#!/usr/bin/env python3
"""Offline-only Ramp contract/transport tests; curl and ramp never reach network."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/ramp'
USER = {'id': '12345678-1234-1234-1234-123456789abc', 'email': 'fixture@example.test', 'role': 'BUSINESS_USER', 'status': 'USER_ACTIVE', 'scheduled_deactivation_date': None, 'phone': 'DO-NOT-EXPORT'}
ROLE = {'id': 'role-id', 'name': 'Reviewer', 'base_role': 'CUSTOM', 'product_capabilities': [{'name': 'EXPENSES_VIEW_EXPENSES', 'access': 'global', 'description': 'View expenses'}]}
EVENT = {'id': 'event-id', 'event_time': '2026-11-01T01:00:00Z', 'event_type': 'Login methods updated', 'actor_id': None, 'actor_type': 'ramp', 'additional_details': 'DO-NOT-EXPORT'}
CONNECTION = {'id': 'connection-id', 'connection_type': 'API', 'is_active': True, 'remote_provider_name': None, 'created_at': '2026-01-01T00:00:00Z', 'last_linked_at': None, 'settings': {'secret': 'DO-NOT-EXPORT'}}
WEBHOOK = {'id': 'webhook-id', 'status': 'active', 'endpoint_url': 'https://example.test/hooks', 'event_types': ['transactions.cleared'], 'created_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T00:00:00Z', 'secret': 'DO-NOT-EXPORT'}
FUND = {'id': 'fund-id', 'display_name': 'Training', 'state': 'ACTIVE', 'is_shareable': False, 'is_exempt_from_policy_agent': False, 'overrides_spend_program': False, 'spend_program_id': None, 'permitted_spend_types': {'physical_card_enabled': True, 'virtual_card_enabled': False, 'reimbursements_enabled': False}, 'spending_restrictions': None, 'balance': 'DO-NOT-EXPORT', 'cards': ['DO-NOT-EXPORT']}
PROGRAM = {'id': 'program-id', 'display_name': 'Training', 'is_shareable': False, 'permitted_spend_types': {'primary_card_enabled': True, 'reimbursements_enabled': False}, 'restrictions': None}

def page(rows, next_url=None):
    return {'data': rows, 'page': {'next': next_url}}

MOCK_CURL = r'''#!/usr/bin/env python3
import json, os, pathlib, stat, sys
args=sys.argv[1:]
assert args[0]=='-q'
assert '--location' not in args and '-L' not in args
assert args[args.index('--request')+1]=='GET'
assert args[args.index('--proto')+1]=='=https'
assert args[args.index('--noproxy')+1]=='*'
assert 'fixture-token' not in ' '.join(args)
assert 'RAMP_ACCESS_TOKEN' not in os.environ
conf=pathlib.Path(args[args.index('--config')+1])
assert stat.S_IMODE(conf.stat().st_mode)==0o600
assert stat.S_IMODE(conf.parent.stat().st_mode)==0o700
assert conf.read_text()=='header = "Authorization: Bearer fixture-token"\n'
log=pathlib.Path(os.environ['MOCK_LOG'])
old=log.read_text().splitlines() if log.exists() else []
url=args[args.index('--url')+1]
with log.open('a') as f:f.write(url+'\n')
items=json.loads(pathlib.Path(os.environ['MOCK_RESPONSES']).read_text())
r=items[len(old)]
if r.get('transport'):
 print('SECRET-ERROR-BODY',file=sys.stderr);sys.exit(7)
pathlib.Path(args[args.index('--output')+1]).write_text(r.get('raw',json.dumps(r.get('body'))))
print(r.get('status','200'),end='')
'''
MOCK_RAMP = r'''#!/usr/bin/env python3
import os, pathlib, sys
p=pathlib.Path(os.environ['MOCK_LOG'])
with p.open('a') as f:f.write(' '.join(sys.argv[1:])+'\n')
assert '--no-input' in sys.argv and '--env' in sys.argv
assert 'login' not in sys.argv
assert '--output' in sys.argv and sys.argv[sys.argv.index('--output')+1]=='json'
if 'users' in sys.argv: assert '--rationale' in sys.argv and sys.argv[sys.argv.index('--rationale')+1]
if os.environ.get('MOCK_CLI_FAIL') and 'users' in sys.argv:
 print('SECRET-ERROR-BODY',file=sys.stderr);sys.exit(1)
print('{"identity":"fixture"}')
'''

class RampPacks(unittest.TestCase):
    def run_pack(self, control, responses=(), env=None, args=(), cli=False, success=True):
        with tempfile.TemporaryDirectory() as d:
            tmp = Path(d)
            for name, content in [('curl', MOCK_CURL), ('ramp', MOCK_RAMP)]:
                p = tmp / name; p.write_text(content); p.chmod(0o700)
            (tmp / 'responses').write_text(json.dumps(responses))
            e = {**os.environ, 'PATH': str(tmp) + os.pathsep + os.environ['PATH'], 'RAMP_ACCESS_TOKEN': 'fixture-token', 'MOCK_RESPONSES': str(tmp / 'responses'), 'MOCK_LOG': str(tmp / 'calls'), 'RAMP_FROM_UTC': '2026-11-01T00:00:00Z', 'RAMP_TO_UTC': '2026-11-02T00:00:00Z'}
            e.pop('RAMP_API_ORIGIN', None)
            e.update(env or {})
            pack = next((PACKS / ('cli' if cli else 'api')).glob('hth-ramp-' + control + '-*.sh'))
            proc = subprocess.run(['bash', str(pack), *args], env=e, capture_output=True, text=True)
            calls = (tmp / 'calls').read_text().splitlines() if (tmp / 'calls').exists() else []
            self.assertEqual(proc.returncode == 0, success, proc.stderr)
            self.assertNotIn('fixture-token', proc.stdout + proc.stderr)
            self.assertNotIn('SECRET-ERROR-BODY', proc.stdout + proc.stderr)
            self.assertNotIn('DO-NOT-EXPORT', proc.stdout)
            if not success:
                self.assertEqual(proc.stdout, '')
            return proc.stdout, calls

    def test_roles(self):
        out, calls = self.run_pack('1.03', [{'body': page([USER])}, {'body': {'data': [ROLE]}}])
        self.assertEqual(len(calls), 2)
        self.assertEqual(json.loads(out)['roles'][0]['base_role'], 'CUSTOM')

    def test_offboarding_includes_suspended_and_no_mutation(self):
        suspended = {**USER, 'id': 'suspended-id', 'status': 'USER_SUSPENDED'}
        out, calls = self.run_pack('1.04', [{'body': page([USER])}, {'body': page([suspended])}])
        self.assertEqual(len(json.loads(out)['users']), 2)
        self.assertIn('status=USER_SUSPENDED', calls[-1])
        self.run_pack('1.04', args=['--apply'], success=False)

    def test_inventory_shapes(self):
        for control, body, key in [('2.03', {'connections': [CONNECTION]}, 'accounting'), ('2.05', [WEBHOOK], 'webhooks')]:
            with self.subTest(control=control):
                out, _ = self.run_pack(control, [{'body': body}])
                self.assertEqual(len(json.loads(out)[key]), 1)
        self.run_pack('3.01', [{'body': page([FUND])}, {'body': page([PROGRAM])}])

    def test_empty_valid(self):
        for control, response in [('2.03', {'connections': []}), ('2.05', []), ('5.01', page([]))]:
            self.run_pack(control, [{'body': response}])

    def test_pagination(self):
        nxt = 'https://api.ramp.com/developer/v1/users?page_size=100&start=cursor'
        out, calls = self.run_pack('1.03', [{'body': page([USER], nxt)}, {'body': page([{**USER, 'id': 'second'}])}, {'body': {'data': []}}])
        self.assertEqual(len(json.loads(out)['users']), 2)
        self.assertEqual(calls[1], nxt)

    def test_audit_pagination_and_projection(self):
        nxt = 'https://api.ramp.com/developer/v1/audit-logs/events?from_date=2026-11-01T00%3A00%3A00Z&to_date=2026-11-02T00%3A00%3A00Z&page_size=100&start=c'
        out, _ = self.run_pack('5.01', [{'body': page([EVENT], nxt)}, {'body': page([{**EVENT, 'id': 'second'}])}])
        events = [json.loads(v) for v in out.splitlines()]
        self.assertEqual(len(events), 2)
        self.assertEqual(set(events[0]), {'id', 'event_time', 'event_type', 'actor_id', 'actor_type'})

    def test_http_and_transport_errors(self):
        for response in [{'status': str(v), 'body': {'error': 'SECRET-ERROR-BODY'}} for v in [301, 302, 400, 401, 403, 429, 500]] + [{'transport': True}, {'raw': 'not-json'}, {'raw': '{"connections":[],"connections":[]}'}, {'raw': '[NaN]'}]:
            with self.subTest(response=response):
                self.run_pack('2.05', [response], success=False)

    def test_partial_failure_is_not_success(self):
        self.run_pack('1.03', [{'body': page([USER])}, {'status': '403'}], success=False)
        nxt = 'https://api.ramp.com/developer/v1/users?page_size=100&start=c'
        self.run_pack('1.03', [{'body': page([USER], nxt)}, {'status': '500'}], success=False)
        self.run_pack('3.01', [{'body': page([FUND])}, {'body': {'unexpected': []}}], success=False)

    def test_host_and_header_injection_before_network(self):
        for token in ['', 'x\nheader: evil', 'x\r\n', 'x"', 'x\\', 'x y']:
            _, calls = self.run_pack('2.05', env={'RAMP_ACCESS_TOKEN': token}, success=False)
            self.assertEqual(calls, [])
        for host in ['https://evil.test', 'https://api.ramp.com@evil.test', 'http://api.ramp.com', 'https://api.ramp.com/']:
            _, calls = self.run_pack('2.05', env={'RAMP_API_ORIGIN': host}, success=False)
            self.assertEqual(calls, [])

    def test_unsafe_pagination(self):
        base = 'https://api.ramp.com/developer/v1/users'
        invalid = ['https://evil.test/a', '//api.ramp.com/developer/v1/users', base.replace('https:', 'http:') + '?start=c&page_size=100', base.replace('api.ramp.com', 'api.ramp.com@evil.test') + '?start=c&page_size=100', base.replace('/users', '/cards') + '?start=c&page_size=100', base + '?page_size=100', base + '?page_size=99&start=c', base + '?page_size=100&start=c&start=d', base + '?page_size=100&start=c#fragment', base + '?page_size=100&start=c\n', base + '?page_size=100&start=c&extra=x', '', False, []]
        for nxt in invalid:
            with self.subTest(next=nxt):
                _, calls = self.run_pack('1.03', [{'body': page([USER], nxt)}], success=False)
                self.assertEqual(len(calls), 1)

    def test_page_bound(self):
        nxt = 'https://api.ramp.com/developer/v1/users?page_size=100&start=c'
        _, calls = self.run_pack('1.03', [{'body': page([USER], nxt)}], env={'RAMP_MAX_PAGES': '1'}, success=False)
        self.assertEqual(len(calls), 1)
        for value in ['0', '-1', '1001', 'x', '01']:
            _, calls = self.run_pack('1.03', env={'RAMP_MAX_PAGES': value}, success=False)
            self.assertEqual(calls, [])

    def test_loop(self):
        nxt = 'https://api.ramp.com/developer/v1/users?page_size=100&start=c'
        self.run_pack('1.03', [{'body': page([USER], nxt)}, {'body': page([USER], nxt)}], success=False)

    def test_malformed_schema(self):
        for response in [{}, {'data': [], 'page': {}}, {'data': {}, 'page': {'next': None}}, page([{}]), page([{**USER, 'role': 3}]), page([None])]:
            with self.subTest(response=response):
                self.run_pack('1.03', [{'body': response}], success=False)
        self.run_pack('2.03', [{'body': {'connections': [{**CONNECTION, 'is_active': 'yes'}]}}], success=False)
        self.run_pack('2.05', [{'body': [dict(WEBHOOK, event_types='wrong')]}], success=False)

    def test_invalid_dates_no_requests(self):
        for start, end in [('yesterday', 'today'), ('2026-02-30T00:00:00Z', '2026-11-02T00:00:00Z'), ('2026-11-02T00:00:00Z', '2026-11-01T00:00:00Z'), ('2026-11-01T00:00:00+00:00', '2026-11-02T00:00:00Z')]:
            _, calls = self.run_pack('5.01', env={'RAMP_FROM_UTC': start, 'RAMP_TO_UTC': end}, success=False)
            self.assertEqual(calls, [])

    def test_cli_read_only_calls(self):
        out, calls = self.run_pack('2.02', cli=True)
        self.assertEqual(len(calls), 2)
        self.assertTrue(calls[0].startswith('auth status '))
        self.assertTrue(calls[1].startswith('users me '))
        self.run_pack('2.02', cli=True, env={'MOCK_CLI_FAIL': '1'}, success=False)

    def test_chrome_native_policy(self):
        policy = next((PACKS / 'config').glob('hth-ramp-2.06-*.jsonc'))
        source = policy.read_text()
        self.assertIn('//   profile: L2', source)
        self.assertIn('//   mode: mutating', source)
        clean = '\n'.join(line for line in source.splitlines() if not line.lstrip().startswith('//'))
        parsed = json.loads(clean)
        self.assertEqual(set(parsed), {'ExtensionInstallForcelist'})
        self.assertEqual(parsed['ExtensionInstallForcelist'], ['idefohglmnkliiadgfofeokcpjobdeik;https://clients2.google.com/service/update2/crx'])
        for entry in parsed['ExtensionInstallForcelist']:
            extension_id, update_url = entry.split(';')
            self.assertRegex(extension_id, r'^[a-p]{32}$')
            self.assertEqual(update_url, 'https://clients2.google.com/service/update2/crx')
        # Exercise the exact documented conversion without installing the result.
        converted = subprocess.run(['sed', r'/^[[:space:]]*\/\//d', str(policy)], capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(converted.stdout), parsed)

    def test_bash_syntax_and_contracts(self):
        for p in PACKS.rglob('*.sh'):
            subprocess.run(['bash', '-n', str(p)], check=True)
            if p.name.startswith('hth-'):
                self.assertIn('#   mode: read-only', p.read_text())
                expected = 'L2' if '2.02-' in p.name or '2.05-' in p.name else 'L1'
                self.assertIn('#   profile: ' + expected, p.read_text())
                self.assertIn('HTH Guide Excerpt: begin', p.read_text())

if __name__ == '__main__':
    unittest.main(verbosity=2)
