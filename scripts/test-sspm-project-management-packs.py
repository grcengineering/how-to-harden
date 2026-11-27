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
    def check(self, vendor, env, responses, status=0):
        pack, = (ROOT / 'packs' / vendor).glob('*/*.sh')
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            shared = folder / 'fixture.json'
            shared.write_text(json.dumps(responses))
            for name in ('curl', 'basecamp'):
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

    def test_basecamp_cli_discards_personal_fields(self):
        claim = self.check('basecamp', {'BASECAMP_REVIEW_ACCOUNT_ID': '42'}, [
            {'required': ['--account', '42', 'people', 'list', '--all', '--json'],
             'body': {'ok': True, 'data': [
                 {'id': 7, 'employee': True, 'admin': False, 'client': False, 'email_address': 'unused'},
             ]}},
        ])
        self.assertEqual(claim, {'requested_account': '42', 'people': [
            {'id': 7, 'employee': True, 'admin': False, 'client': False},
        ]})

    def test_coda_paginates_without_following_link(self):
        got = self.check('coda', {'CODA_ADMIN_TOKEN': 'mock', 'CODA_ORG_ID': 'org-DEMO'}, [
            {'required': ['https://coda.io/apis/admin/v1/organizations/org-DEMO/workspaces'],
             'body': {'items': [{'id': 'ws-b'}], 'nextPageToken': 'again', 'nextPageLink': 'ignored'}},
            {'required': ['pageToken=again'], 'body': {'items': [{'id': 'ws-a', 'name': 'irrelevant'}]}},
        ])
        self.assertEqual(got, ['ws-a', 'ws-b'])

    def test_coda_missing_items_not_empty_success(self):
        self.assertIsNone(self.check('coda', {'CODA_ADMIN_TOKEN': 'mock', 'CODA_ORG_ID': 'org-DEMO'}, [
            {'body': {'unexpected': []}},
        ], status=5))

    def test_mural_paginates(self):
        got = self.check('mural', {'MURAL_TOKEN': 'mock'}, [
            {'body': {'value': [{'id': 'ws-1'}], 'next': 'more'}},
            {'required': ['next=more'], 'body': {'value': [{'id': 'ws-2'}]}},
        ])
        self.assertEqual(got, ['ws-1', 'ws-2'])

    def test_mural_unauthorized_not_empty_success(self):
        self.assertIsNone(self.check('mural', {'MURAL_TOKEN': 'mock'}, [{'http_error': True}], status=22))

    def test_wrike_exact_account_and_minimal_profile(self):
        got = self.check('wrike', {'WRIKE_OAUTH_HOST': 'www.wrike.com', 'WRIKE_EXPECTED_ACCOUNT_ID': 'TEST', 'WRIKE_TOKEN': 'mock'}, [
            {'required': ['me=true'], 'body': {'kind': 'contacts', 'data': [
                {'me': True, 'id': 'CALLER', 'profiles': [
                    {'accountId': 'DIFFERENT', 'admin': True, 'owner': True, 'external': False},
                    {'accountId': 'TEST', 'admin': False, 'owner': False, 'external': True, 'email': 'not retained'},
                ]},
            ]}},
        ])
        self.assertEqual(got, {'account': 'TEST', 'contact': 'CALLER', 'admin': False, 'owner': False, 'external': True})

    def test_wrike_unrecognized_host_does_not_use_network(self):
        self.assertIsNone(self.check('wrike', {'WRIKE_OAUTH_HOST': 'invalid', 'WRIKE_EXPECTED_ACCOUNT_ID': 'TEST', 'WRIKE_TOKEN': 'mock'}, [], status=2))


if __name__ == '__main__':
    unittest.main()
