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
    if '--header' in argv and '@-' in argv:
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
            for name in ('curl',):
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

    def test_businessmap_contract_is_not_post_or_tenant_state(self):
        claim = self.check('businessmap', {'BUSINESSMAP_SUBDOMAIN': 'sample'}, [
            {'required': ['https://sample.kanbanize.com/openapi/json'],
             'body': {'openapi': '3.1.0', 'paths': {'/users': {'get': {}}, '/api/v2/users': {'post': {}}}}},
        ])
        self.assertEqual(claim, {'tenant': 'sample', 'scope': 'schema-only', 'http_method': 'GET', 'documented_paths': ['/users']})

    def test_businessmap_rejects_unsigned_shape(self):
        got = self.check('businessmap', {'BUSINESSMAP_SUBDOMAIN': 'sample'},
                         [{'body': {'paths': {'/users': {'get': {}}}}}], status=5)
        self.assertIsNone(got)

    def test_kanban_token_identity_readback(self):
        got = self.check('kanban-tool', {
            'KANBAN_TOOL_SUBDOMAIN': 'sample', 'KANBAN_TOOL_EXPECTED_USER_ID': '42', 'KANBAN_TOOL_TOKEN': 'mock',
        }, [{'required': ['https://sample.kanbantool.com/api/v3/users/current.json'],
             'body': {'id': 42, 'name': 'ignore', 'boards': []}}])
        self.assertEqual(got, {'id': 42, 'verified_identity': True})

    def test_kanban_wrong_identity_not_success(self):
        got = self.check('kanban-tool', {
            'KANBAN_TOOL_SUBDOMAIN': 'sample', 'KANBAN_TOOL_EXPECTED_USER_ID': '42', 'KANBAN_TOOL_TOKEN': 'mock',
        }, [{'body': {'id': 41}}], status=5)
        self.assertIsNone(got)

    def test_youtrack_ban_and_drift(self):
        for state in (True, False):
            with self.subTest(state=state):
                got = self.check('youtrack-cloud', {
                    'YOUTRACK_SUBDOMAIN': 'sample', 'YOUTRACK_USER_ID': '24-42', 'YOUTRACK_TOKEN': 'mock',
                }, [{'required': ['fields=id,banned', 'https://sample.youtrack.cloud/api/users/24-42'],
                     'body': {'id': '24-42', 'banned': state, 'name': 'ignore'}}], status=0 if state else 1)
                self.assertEqual(got, {'id': '24-42', 'banned': state})

    def test_lucid_explicit_inactive(self):
        got = self.check('lucidchart', {
            'LUCID_SCIM_USER_ID': 'USER', 'LUCID_SCIM_EXPECTED_ACTIVE': 'false', 'LUCID_SCIM_TOKEN': 'mock',
        }, [{'required': ['https://users.lucid.app/scim/v2/Users/USER'],
             'body': {'id': 'USER', 'active': False, 'emails': ['ignore']}}])
        self.assertEqual(got, {'id': 'USER', 'active': False, 'matches': True})

    def test_lucid_404_not_inactive(self):
        assert self.check('lucidchart', {
            'LUCID_SCIM_USER_ID': 'USER', 'LUCID_SCIM_EXPECTED_ACTIVE': 'false', 'LUCID_SCIM_TOKEN': 'mock',
        }, [{'http_error': True}], status=22) is None


if __name__ == '__main__':
    unittest.main()
