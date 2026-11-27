#!/usr/bin/env python3
"""Exercise each HTH pack's entry point against local command stubs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STUB = '''#!/usr/bin/env python3
import json, os, pathlib, sys
argv = sys.argv[1:]
p = pathlib.Path(os.environ['FIXTURE'])
responses = json.loads(p.read_text())
response = responses.pop(0)
p.write_text(json.dumps(responses))
if pathlib.Path(sys.argv[0]).name == 'curl':
    assert '-q' in argv and '--fail' in argv and '--location' not in argv
    assert sys.stdin.read().startswith('Authorization: Bearer ')
if 'required' in response:
    assert all(arg in argv for arg in response['required']), argv
if response.get('http_error'):
    sys.exit(22)
print(json.dumps(response['body']))
'''


class Packs(unittest.TestCase):
    def check(self, vendor, env, responses, status=0, kind="api"):
        pack, = (ROOT / 'packs' / vendor).glob(f'{kind}/*.sh')
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            shared = folder / 'fixture.json'
            shared.write_text(json.dumps(responses))
            for name in ('curl', 'lokalise2'):
                p = folder / name
                p.write_text(STUB)
                p.chmod(0o755)
            result = subprocess.run(
                ['bash', str(pack)], capture_output=True, text=True, check=False,
                env={**os.environ, **env, "FIXTURE": str(shared), "PATH": f"{d}:{os.environ['PATH']}"},
            )
            self.assertEqual(result.returncode, status, result.stderr)
            self.assertEqual(json.loads(shared.read_text()), [])
            return json.loads(result.stdout) if result.stdout else None

    def test_aha_auth_scope_and_complete_pagination(self):
        got = self.check('aha-roadmaps', {
            'AHA_SUBDOMAIN': 'sample', 'AHA_OPERATIONS_EMAIL': 'owner@example.test', 'AHA_TOKEN': 'mock',
        }, [
            {'required': ['https://sample.aha.io/api/v1/users', 'page=1'],
             'body': {'users': [{'id': '123', 'email': 'ignore'}], 'pagination': {'current_page': 1, 'total_pages': 2}}},
            {'required': ['page=2'],
             'body': {'users': [{'id': '456'}], 'pagination': [{'current_page': 2, 'total_pages': 2}]}},
        ])
        self.assertEqual(got, ['123', '456'])

    def test_aha_invalid_subdomain_not_request(self):
        self.assertIsNone(self.check('aha-roadmaps', {
            'AHA_SUBDOMAIN': 'sample.aha.io', 'AHA_OPERATIONS_EMAIL': 'owner@example.test', 'AHA_TOKEN': 'mock',
        }, [], status=2))

    def test_articulate_roles_and_regions(self):
        for region, host in [('eu', 'api.reach360.eu'), ('us', 'api.reach360.com')]:
            with self.subTest(region=region):
                got = self.check('articulate-360', {
                    'REACH360_REGION': region, 'REACH360_USER_ID': 'approved-user', 'REACH360_APPROVED_ROLE': 'learner',
                    'REACH360_API_KEY': 'mock',
                }, [{'required': [f'https://{host}/users/approved-user'],
                     'body': {'id': 'approved-user', 'role': 'admin', 'email': 'ignore'}}], status=1)
                self.assertEqual(got, {'id': 'approved-user', 'role': 'admin', 'matches': False})

    def test_crowdin_enrollment(self):
        got = self.check('crowdin-enterprise', {
            'CROWDIN_ORG_SUBDOMAIN': 'sample', 'CROWDIN_USER_ID': '42', 'CROWDIN_TOKEN': 'mock',
        }, [{'required': ['https://sample.api.crowdin.com/api/v2/users/42'],
             'body': {'data': {'id': 42, 'status': 'active', 'twoFactor': 'enabled', 'email': 'ignore'}}}])
        self.assertEqual(got, {'id': 42, 'status': 'active', 'twoFactor': 'enabled'})

    def test_lokalise_api_and_cli_scope(self):
        with tempfile.TemporaryDirectory() as d:
            config = Path(d) / 'config.yml'
            config.write_text('# Empty: all requests are stubbed')
            config.chmod(0o600)
            response = {'team_id': 22, 'team_user': {'user_id': 33, 'role': 'admin', 'email': 'ignore'}}
            base_env = {'LOKALISE_TEAM_ID': '22', 'LOKALISE_USER_ID': '33'}
            for kind, env, required in [
                    ('api', {'LOKALISE_OAUTH_TOKEN': 'mock'}, ['https://api.lokalise.com/api2/teams/22/users/33']),
                    ('cli', {'LOKALISE_APPROVED_CLI_CONFIG': str(config)}, ['team-user', 'retrieve', '--team-id', '22', '--user-id', '33']),
            ]:
                with self.subTest(kind=kind):
                    got = self.check('lokalise', {**base_env, **env}, [{'required': required, 'body': response}], kind=kind)
                    self.assertEqual(got, {'team_id': 22, 'user_id': 33, 'role': 'admin'})

    def test_lokalise_wrong_team_not_success(self):
        got = self.check('lokalise', {'LOKALISE_TEAM_ID': '22', 'LOKALISE_USER_ID': '33', 'LOKALISE_OAUTH_TOKEN': 'mock'},
                         [{'body': {'team_id': 11, 'team_user': {'user_id': 33, 'role': 'admin'}}}], status=5)
        self.assertIsNone(got)


if __name__ == '__main__':
    unittest.main()
