#!/usr/bin/env python3
"""Offline safety/contract tests; fake curl, Droid and SDK never contact Factory.

Run: python3 scripts/test-factory-packs.py
Requires Python standard library, bash and jq. SDK compatibility is doc-checked,
not proven by these mocks; no Factory tenant or installed SDK is required.
"""
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/factory'
TOKEN = 'fk-SYNTHETIC_ONLY_NOT_A_REAL_KEY'
PRIVATE = 'SYNTHETIC_PRIVATE_RESPONSE'
FILES = {
    'members': 'api/hth-factory-1.02-inventory-members.sh',
    'keys': 'api/hth-factory-1.03-audit-workload-keys.sh',
    'history': 'api/hth-factory-5.02-collect-control-history.sh',
    'ip': 'config/hth-factory-4.01-build-source-ip-policy.sh',
    'models': 'config/hth-factory-4.02-build-model-policy.sh',
    'telemetry': 'config/hth-factory-5.01-build-private-telemetry.sh',
    'rules': 'cli/hth-factory-2.02-check-permission-rules.sh',
    'mcp': 'cli/hth-factory-3.01-inventory-mcp-approvals.sh',
    'plugins': 'cli/hth-factory-3.02-inventory-plugins.sh',
    'network_tools': 'cli/hth-factory-2.05-inventory-network-tools.sh',
    'computers': 'cli/hth-factory-4.04-inventory-visible-computers.sh',
    'sdk': 'sdk/hth-factory-4.02-verify-model-catalog.py',
}

FAKE_CURL = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
assert args[0] == '-q'
assert args[args.index('--request') + 1] == 'GET'
assert '--location' not in args and '-L' not in args
assert args[args.index('--proto') + 1] == '=https'
assert '--tlsv1.2' in args and '--max-time' in args
assert os.environ['FACTORY_API_KEY'] not in ' '.join(args)
assert sys.stdin.read() == 'header = "Authorization: Bearer ' + os.environ['FACTORY_API_KEY'] + '"\n'
state = pathlib.Path(os.environ['FACTORY_TEST_STATE'])
position = int(state.read_text()) if state.exists() else 0
responses = json.loads(pathlib.Path(os.environ['FACTORY_TEST_RESPONSES']).read_text())
assert position < len(responses), 'unexpected additional request'
response = responses[position]
assert args[-1] == 'https://api.factory.ai' + response['path'], args[-1]
state.write_text(str(position + 1))
if response.get('transport_error'):
    sys.exit(7)
pathlib.Path(args[args.index('--output') + 1]).write_text(response.get('raw', json.dumps(response.get('body', {}))))
print(response.get('status', 200), end='')
'''

FAKE_DROID = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
record = pathlib.Path(os.environ['FACTORY_TEST_CLI_CALLS'])
with record.open('a') as target:
    target.write(json.dumps(args) + '\n')
if os.environ.get('FACTORY_TEST_CLI_ERROR'):
    print('SYNTHETIC_PRIVATE_RESPONSE', file=sys.stderr)
    print(os.environ.get('FACTORY_API_KEY', ''), file=sys.stderr)
    sys.exit(1)
if args[:2] == ['rules', 'check']:
    assert args[args.index('--command') + 1] == 'git push origin main'
    assert '--json' in args
    if '--file' in args:
        rules = json.loads(pathlib.Path(args[args.index('--file') + 1]).read_text())
        assert set(rules) == {'version', 'rules'}, 'full settings wrapper passed to --file'
        report = {'decision': 'block', 'fixture': 'candidate'}
    else:
        report = {'decision': 'no-match', 'fixture': 'resolved'}
    print('not-json' if os.environ.get('FACTORY_TEST_CLI_BAD_JSON') else json.dumps(report))
elif args in (['mcp', 'list'], ['mcp', 'permissions', 'list'], ['plugin', 'list'],
              ['exec', '--list-tools'], ['computer', 'list']):
    print('SYNTHETIC_PRIVATE_RESPONSE')
else:
    raise AssertionError('unexpected or mutating Droid command: ' + repr(args))
'''

FAKE_SDK = '''import json, os
from pathlib import Path
from types import SimpleNamespace

async def list_models(*, include_disabled, cwd):
    assert include_disabled is True
    assert cwd == Path(os.environ['FACTORY_PROJECT_DIR'])
    Path(os.environ['FACTORY_TEST_SDK_CALLED']).write_text('discovery only')
    if os.environ.get('FACTORY_TEST_SDK_ERROR'):
        raise RuntimeError('SYNTHETIC_PRIVATE_RESPONSE')
    return [SimpleNamespace(**m) for m in json.loads(os.environ['FACTORY_TEST_MODELS'])]

async def run(*args, **kwargs):
    raise AssertionError('a model call must never be made')
'''


def page(key, items, more=False, cursor=None):
    return {key: items, 'pagination': {'hasMore': more, 'nextCursor': cursor}}


def reply(path, body=None, **kw):
    return dict(path=path, body=body, **kw)


class FactoryPackTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='hth-factory-test-')
        self.directory = Path(self.temp.name)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith(('FACTORY_', 'HTH_'))}
        for name, content in [('curl', FAKE_CURL), ('droid', FAKE_DROID)]:
            binary = self.directory / name
            binary.write_text(content)
            binary.chmod(0o700)
        (self.directory / 'droid_sdk.py').write_text(FAKE_SDK)
        self.output = self.directory / 'evidence.json'
        self.expected = self.directory / 'approved.json'
        self.expected.write_text('["approved-model"]')
        self.ips = self.directory / 'ips.json'
        self.ips.write_text('["198.51.100.2", "203.0.113.19/24"]')
        self.settings = self.directory / 'settings.json'
        self.settings.write_text('{"permissionRules":{"version":1,"rules":[]},"maxAutonomyLevel":"low"}')
        self.env.update({
            'PATH': str(self.directory) + ':' + os.environ['PATH'],
            'PYTHONPATH': str(self.directory), 'PYTHONDONTWRITEBYTECODE': '1',
            'HTH_PROFILE_LEVEL': '3', 'TMPDIR': str(self.directory),
            'FACTORY_API_KEY': TOKEN, 'FACTORY_PROJECT_DIR': str(self.directory),
            'FACTORY_SETTINGS_FILE': str(self.settings),
            'FACTORY_APPROVED_MODEL_IDS_FILE': str(self.expected),
            'FACTORY_ALLOWED_IPS_FILE': str(self.ips),
            'FACTORY_OTLP_ENDPOINT': 'https://collector.example.invalid:4318',
            'FACTORY_OTLP_TOKEN': PRIVATE,
            'FACTORY_TEST_STATE': str(self.directory / 'state'),
            'FACTORY_TEST_RESPONSES': str(self.directory / 'responses.json'),
            'FACTORY_TEST_CLI_CALLS': str(self.directory / 'cli.jsonl'),
            'FACTORY_TEST_SDK_CALLED': str(self.directory / 'sdk-called'),
            'FACTORY_TEST_MODELS': '[{"id":"approved-model","disabled":false}]',
        })
        for name in ('MEMBERS', 'KEYS', 'HISTORY', 'RULE_REPORT', 'MCP', 'PLUGINS', 'MODEL', 'TOOLS', 'COMPUTERS'):
            self.env['FACTORY_' + name + '_OUTPUT'] = str(self.output)

    def tearDown(self):
        self.temp.cleanup()

    def run_pack(self, name, responses=(), expected=0, **env):
        (self.directory / 'responses.json').write_text(json.dumps(responses))
        current = dict(self.env, **env)
        executable = 'python3' if name == 'sdk' else 'bash'
        result = subprocess.run([executable, str(PACKS / FILES[name])], env=current,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        self.assertNotIn(TOKEN, result.stdout + result.stderr)
        self.assertNotIn(PRIVATE, result.stdout + result.stderr)
        self.assertNotIn('person@example.invalid', result.stdout + result.stderr)
        self.assertFalse(list(self.directory.glob('hth-factory.*')), 'temporary evidence not cleaned')
        return result

    def members(self, items=None, **kw):
        return reply('/api/v0/organization/users?limit=100',
                     page('users', items if items is not None else [{'id': 'u1', 'email': 'person@example.invalid'}], **kw))

    def history(self, items):
        return reply('/api/v0/organization/enterprise-controls/history?limit=100', page('changes', items))

    def assert_private(self):
        self.assertEqual(stat.S_IMODE(self.output.stat().st_mode), 0o600)
        return json.loads(self.output.read_text())

    def test_profile_gate_before_requests(self):
        for name in FILES:
            with self.subTest(pack=name):
                level = '0' if name in ('members', 'keys') else '1'
                self.run_pack(name, expected=2, HTH_PROFILE_LEVEL=level)
        self.assertFalse((self.directory / 'state').exists())
        self.assertFalse((self.directory / 'sdk-called').exists())

    def test_token_and_origin_rejected_before_requests(self):
        for changes in ({'FACTORY_API_KEY': ''}, {'FACTORY_API_KEY': TOKEN + '\nheader = "x: y"'},
                        {'FACTORY_API_BASE': 'https://example.invalid'}):
            with self.subTest(changes=list(changes)):
                self.run_pack('members', expected=2, **changes)
        self.assertFalse((self.directory / 'state').exists())

    def test_members_all_pages_and_encoded_cursor(self):
        self.run_pack('members', [self.members(more=True, cursor='a& b'),
            reply('/api/v0/organization/users?limit=100&cursor=a%26%20b', page('users', [{'id': 'u2', 'email': 'other@example.invalid'}]))])
        self.assertEqual(len(self.assert_private()['users']), 2)

    def test_empty_inventory_is_collection_not_compliance(self):
        result = self.run_pack('members', [self.members([])])
        self.assertIn('COLLECTED', result.stdout)
        self.assertNotIn('PASS', result.stdout)
        self.assertEqual(self.assert_private()['users'], [])

    def test_http_and_transport_failures_do_not_accept_evidence(self):
        for response in [reply('/api/v0/organization/users?limit=100', {PRIVATE: TOKEN}, status=401),
                         reply('/api/v0/organization/users?limit=100', {}, status=302),
                         reply('/api/v0/organization/users?limit=100', {}, status=429),
                         reply('/api/v0/organization/users?limit=100', raw='not JSON'),
                         reply('/api/v0/organization/users?limit=100', transport_error=True)]:
            with self.subTest(response=response.get('status', response.get('raw', 'transport'))):
                (self.directory / 'state').unlink(missing_ok=True)
                self.run_pack('members', [response], expected=2)
                self.assertFalse(self.output.exists())

    def test_duplicate_and_invalid_members_fail(self):
        for members in ([{'id': 'u', 'email': 'a'}, {'id': 'u', 'email': 'b'}], [{'id': None, 'email': 'a'}]):
            with self.subTest(members=members):
                (self.directory / 'state').unlink(missing_ok=True)
                self.run_pack('members', [self.members(members)], expected=2)
                self.assertFalse(self.output.exists())

    def test_incomplete_pagination_fails(self):
        for body in [page('users', [{'id': 'u', 'email': 'a'}], True),
                     page('users', [], True, 'next'),
                     {'users': [], 'pagination': {'hasMore': 'false', 'nextCursor': None}},
                     {'users': [], 'pagination': {'hasMore': False}}]:
            with self.subTest(body=body):
                (self.directory / 'state').unlink(missing_ok=True)
                self.run_pack('members', [reply('/api/v0/organization/users?limit=100', body)], expected=2)
                self.assertFalse(self.output.exists())

    def test_repeated_cursor_fails(self):
        self.run_pack('members', [self.members(more=True, cursor='next'),
            reply('/api/v0/organization/users?limit=100&cursor=next',
                  page('users', [{'id': 'u2', 'email': 'b'}], True, 'next'))], expected=2)
        self.assertFalse(self.output.exists())

    def test_page_limit_fails(self):
        self.run_pack('members', [self.members(more=True, cursor='next')], expected=2, HTH_MAX_PAGES='1')
        self.assertFalse(self.output.exists())

    def test_failed_later_page_discards_partial_results(self):
        self.run_pack('members', [self.members(more=True, cursor='next'),
            reply('/api/v0/organization/users?limit=100&cursor=next', {}, status=503)], expected=2)
        self.assertFalse(self.output.exists())

    def test_existing_and_symlink_outputs_are_not_overwritten(self):
        self.output.write_text('keep')
        self.run_pack('members', [self.members()], expected=2)
        self.assertEqual(self.output.read_text(), 'keep')
        self.output.unlink()
        target = self.directory / 'target'
        target.write_text('keep target')
        self.output.symlink_to(target)
        (self.directory / 'state').unlink()
        self.run_pack('members', [self.members()], expected=2)
        self.assertEqual(target.read_text(), 'keep target')

    def test_service_keys_use_documented_metadata_only(self):
        accounts = {'serviceAccounts': [{'id': 'sa/one', 'name': 'workflow', 'status': 'active'},
                                        {'id': 'gone', 'name': 'gone', 'status': 'deleted'}]}
        keys = {'apiKeys': [{'id': 'k', 'name': 'temporary', 'createdAt': 1700000000000,
                            'isRevoked': False, 'expiresAt': None, 'value': PRIVATE}]}
        self.run_pack('keys', [reply('/api/v0/service-accounts', accounts),
                              reply('/api/v0/service-accounts/sa%2Fone/api-keys', keys)])
        evidence = self.assert_private()
        self.assertNotIn(PRIVATE, self.output.read_text())
        self.assertEqual(len(evidence['serviceAccounts']), 2)
        self.assertEqual(evidence['keyMetadata'][0]['keys'][0]['expiresAt'], None)

    def test_malformed_service_key_status_fails(self):
        self.run_pack('keys', [reply('/api/v0/service-accounts', {'serviceAccounts': [
            {'id': 'sa', 'name': 'workflow', 'status': 'active'}]}),
            reply('/api/v0/service-accounts/sa/api-keys', {'apiKeys': [
                {'id': 'key', 'isRevoked': 'false', 'createdAt': 1}]})], expected=2)
        self.assertFalse(self.output.exists())

    def test_history_accepts_generic_settings_without_logging_them(self):
        event = {'revision': 2, 'settings': {'futureField': PRIVATE}, 'user': {'id': 'u'}, 'updatedAt': '2026-10-30T00:00:00Z'}
        result = self.run_pack('history', [self.history([event])])
        self.assertIn('Historical snapshots', result.stdout)
        self.assertEqual(self.assert_private()['changes'][0]['settings']['futureField'], PRIVATE)

    def test_invalid_and_duplicate_history_fail(self):
        event = {'revision': 2, 'settings': {}, 'user': {}, 'updatedAt': '2026-10-30T00:00:00Z'}
        for records in ([event, event], [dict(event, revision=1.5)], [dict(event, settings=[])]):
            with self.subTest(records=records):
                (self.directory / 'state').unlink(missing_ok=True)
                self.run_pack('history', [self.history(records)], expected=2)

    def test_ip_generator_normalizes_without_requests(self):
        result = self.run_pack('ip')
        self.assertEqual(json.loads(result.stdout)['networkPolicy']['allowedIps'], ['198.51.100.2/32', '203.0.113.0/24'])
        self.assertFalse((self.directory / 'state').exists())

    def test_ip_generator_rejects_unsafe_or_invalid_inputs(self):
        for value in ('[]', '["::1"]', '["0.0.0.0/0"]', '["127.0.0.1"]', '[null]', '{}', 'not JSON'):
            with self.subTest(value=value):
                self.ips.write_text(value)
                self.assertEqual(self.run_pack('ip', expected=2).stdout, '')

    def test_model_generator_has_separate_image_control(self):
        policy = json.loads(self.run_pack('models').stdout)
        self.assertEqual(policy['modelPolicy']['allowedModelIds'], ['approved-model'])
        self.assertFalse(policy['modelPolicy']['allowAllFactoryModels'])
        self.assertFalse(policy['modelPolicy']['allowCustomModels'])
        self.assertFalse(policy['imageGenerationEnabled'])

    def test_model_generator_rejects_bad_approval_lists(self):
        for value in ('[]', '["duplicate","duplicate"]', '[null]', '[" "]', '{}', 'not JSON'):
            with self.subTest(value=value):
                self.expected.write_text(value)
                self.assertEqual(self.run_pack('models', expected=2).stdout, '')

    def test_telemetry_keeps_credential_reference_literal(self):
        config = json.loads(self.run_pack('telemetry').stdout)['telemetry']
        self.assertEqual(config['headers']['Authorization'], 'Bearer ${FACTORY_OTLP_TOKEN}')
        self.assertFalse(config['logMessageContent'])
        self.assertEqual(config['granularity'], 'aggregate')
        self.assertEqual(config['format'], 'genai')

    def test_telemetry_rejects_credential_bearing_or_invalid_urls(self):
        for endpoint in ('http://collector.invalid', 'https://user:pass@collector.invalid',
                         'https://collector.invalid?token=x', 'https://collector.invalid#frag',
                         'https://collector.invalid:bad', 'https://collector.invalid/\nother', 'https://'):
            with self.subTest(endpoint=endpoint):
                self.assertEqual(self.run_pack('telemetry', expected=2, FACTORY_OTLP_ENDPOINT=endpoint).stdout, '')

    def test_cli_rule_file_is_extracted_and_previews_are_distinct(self):
        result = self.run_pack('rules')
        report = self.assert_private()
        self.assertEqual(report['candidate']['decision'], 'block')
        self.assertEqual(report['effective']['decision'], 'no-match')
        self.assertIn('COLLECTED', result.stdout)
        self.assertNotIn('MATCH:', result.stdout)
        calls = [json.loads(x) for x in (self.directory / 'cli.jsonl').read_text().splitlines()]
        self.assertEqual(len(calls), 2)

    def test_cli_errors_and_invalid_reports_are_unknown(self):
        self.run_pack('rules', expected=2, FACTORY_TEST_CLI_ERROR='1')
        self.run_pack('rules', expected=2, FACTORY_TEST_CLI_BAD_JSON='1')
        self.assertFalse(self.output.exists())

    def test_cli_requires_explicit_trusted_directory(self):
        self.run_pack('mcp', expected=2, FACTORY_PROJECT_DIR='relative')
        self.assertFalse((self.directory / 'cli.jsonl').exists())

    def test_cli_mcp_inventory_stays_private(self):
        self.run_pack('mcp')
        evidence = self.assert_private()
        self.assertIn(PRIVATE, evidence['servers'])
        self.assertIn(PRIVATE, evidence['persistentPermissions'])

    def test_cli_plugin_inventory_is_not_enablement_verdict(self):
        result = self.run_pack('plugins')
        self.assertEqual(stat.S_IMODE(self.output.stat().st_mode), 0o600)
        self.assertIn(PRIVATE, self.output.read_text())
        self.assertIn('does not prove', result.stdout)

    def test_sdk_discovers_without_model_call(self):
        self.run_pack('sdk')
        self.assertEqual(self.assert_private()['available'], ['approved-model'])
        self.assertTrue((self.directory / 'sdk-called').exists())

    def test_cli_tool_discovery_exits_without_starting_a_model_task(self):
        self.run_pack('network_tools')
        calls = [json.loads(x) for x in (self.directory / 'cli.jsonl').read_text().splitlines()]
        self.assertEqual(calls, [['exec', '--list-tools']])
        self.assertEqual(stat.S_IMODE(self.output.stat().st_mode), 0o600)

    def test_cli_computer_inventory_does_not_provision_or_remove(self):
        result = self.run_pack('computers')
        self.assertIn('visible to this identity', result.stdout)
        calls = [json.loads(x) for x in (self.directory / 'cli.jsonl').read_text().splitlines()]
        self.assertEqual(calls, [['computer', 'list']])

    def test_sdk_unapproved_and_disabled_models_are_drift(self):
        for models in ([{'id': 'unapproved', 'disabled': False}],
                       [{'id': 'approved-model', 'disabled': True}], []):
            with self.subTest(models=models):
                self.output.unlink(missing_ok=True)
                self.run_pack('sdk', expected=1, FACTORY_TEST_MODELS=json.dumps(models))
                self.assert_private()

    def test_sdk_discovery_failure_does_not_leak_exception(self):
        self.run_pack('sdk', expected=2, FACTORY_TEST_SDK_ERROR='1')
        self.assertFalse(self.output.exists())

    def test_sdk_invalid_catalog_is_unknown(self):
        for models in ([{'id': 'x', 'disabled': 'false'}], [{'id': 'x', 'disabled': False}] * 2):
            with self.subTest(models=models):
                self.run_pack('sdk', expected=2, FACTORY_TEST_MODELS=json.dumps(models))

    def test_sdk_existing_output_is_preserved(self):
        self.output.write_text('keep')
        self.run_pack('sdk', expected=2)
        self.assertEqual(self.output.read_text(), 'keep')

    def test_static_fragments_have_safe_policy_semantics(self):
        fragments = {}
        for path in (PACKS / 'config').glob('*.jsonc'):
            text = '\n'.join(x for x in path.read_text().splitlines() if not x.lstrip().startswith('//'))
            value = json.loads(text)
            self.assertIsInstance(value, dict)
            self.assertNotIn('commandAllowlist', value, 'new policy must not use deprecated lists')
            for key in value:
                self.assertNotIn(key, fragments, 'fragments must merge without replacing another fragment')
            fragments.update(value)
        self.assertTrue(fragments['sandbox']['enabled'])
        self.assertEqual(fragments['sandbox']['mode'], 'whole-process')
        self.assertTrue(fragments['sandbox']['filesystem']['denyRead'])
        self.assertTrue(fragments['mcpPolicy']['enabled'])
        self.assertEqual(fragments['mcpPolicy']['allowlist'], [])
        self.assertTrue(fragments['strictEnabledPlugins'])
        self.assertTrue(fragments['allowManagedHooksOnly'])
        self.assertFalse(fragments['hooksDisabled'])
        self.assertTrue(fragments['webSearchDisabled'])
        self.assertEqual(fragments['builtInToolAutonomyOverrides']['FetchUrl'], 'high')
        ids = [r['id'] for r in fragments['permissionRules']['rules']]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(r['decision'] == 'block' and r['tests']['match'] and r['tests']['noMatch']
                            for r in fragments['permissionRules']['rules']))


if __name__ == '__main__':
    unittest.main()
