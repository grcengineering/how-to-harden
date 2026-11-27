"""Offline behavior for Egnyte, Files.com, ShareFile and Tresorit packs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
EG_USER = {'startIndex': 1, 'totalResults': 4, 'resources': [
    {'id': 1, 'active': True, 'authType': 'sso', 'userType': 'power', 'email': 'OMIT'}
]}
FILES_USER = {'id': 17, 'disabled': False, 'authentication_method': 'sso',
              'require_2fa': 'use_system_setting', 'email': 'OMIT'}
CASES = (
    ('egnyte/api/*-1.01-*.sh', 'https://example.egnyte.com/pubapi/v2/users?count=100&startIndex=1',
     {'EGNYTE_SUBDOMAIN': 'example', 'EGNYTE_ACCESS_TOKEN': 'fixture'}, EG_USER, 'users'),
    ('egnyte/api/*-2.01-*.sh', 'https://example.egnyte.com/pubapi/v2/audit/stream?startDate=2026-11-26',
     {'EGNYTE_SUBDOMAIN': 'example', 'EGNYTE_ACCESS_TOKEN': 'fixture', 'EGNYTE_START_DATE': '2026-11-26'},
     {'nextCursor': 'next', 'moreEvents': True, 'events': [{'auditSource': 'LOGIN_AUDIT', 'actor': 'OMIT'}]},
     'sources'),
    ('files-com/api/*.sh', 'https://example.files.com/api/rest/v1/users/17.json',
     {'FILES_SITE': 'example', 'FILES_USER_ID': '17', 'FILES_API_KEY': 'fixture'}, FILES_USER, 'user'),
    ('sharefile/api/*.sh', 'https://example.sf-api.com/sf/v3/Accounts/Employees',
     {'SHAREFILE_SUBDOMAIN': 'example', 'SHAREFILE_ACCESS_TOKEN': 'fixture'},
     {'odata.nextLink': 'https://example.sf-api.com/sf/v3/Accounts/Employees?offset=1',
      'value': [{'Id': 'fixture-id', 'Email': 'OMIT'}]}, 'employees'),
)


class Packs(unittest.TestCase):
    def run_pack(self, glob, command, script, env):
        pack = next((ROOT / 'packs').glob(glob))
        with tempfile.TemporaryDirectory() as temp:
            mock = Path(temp) / command
            mock.write_text('#!/bin/bash\nset -eu\n' + script)
            mock.chmod(0o700)
            return subprocess.run(['bash', str(pack)], capture_output=True, text=True,
                                  env={**os.environ, **env, 'PATH': temp + os.pathsep + os.environ['PATH']},
                                  check=False)

    def test_api_endpoints_and_projection(self):
        for glob, url, variables, body, key in CASES:
            with self.subTest(pack=glob):
                stub = """[[ "$1" == --disable && "${!#}" == "$EXPECTED_URL" ]] || exit 11
header=$(cat)
[[ "$header" == 'header = "Authorization: Bearer fixture"' ||
   "$header" == 'header = "X-FilesAPI-Key: fixture"' ]] || exit 12
[[ "${MOCK_FAIL:-0}" == 0 ]] || exit 13
printf '%s' "$MOCK_BODY"
"""
                env = {**variables, 'EXPECTED_URL': url, 'MOCK_BODY': json.dumps(body)}
                good = self.run_pack(glob, 'curl', stub, env)
                self.assertEqual(good.returncode, 0, good.stderr)
                self.assertIn(key, json.loads(good.stdout))
                self.assertNotIn('OMIT', good.stdout)
                self.assertNotIn('fixture"', good.stdout)
                if key == 'employees':
                    self.assertTrue(json.loads(good.stdout)['has_next_page'])
                    self.assertNotIn('offset', good.stdout)
                for bad in ({'MOCK_BODY': '{"error":true}'}, {'MOCK_FAIL': '1'}):
                    result = self.run_pack(glob, 'curl', stub, {**env, **bad})
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertFalse(result.stdout)

    def test_cli_entries_use_documented_read_commands(self):
        for glob, cmd, args, env, output in (
            ('egnyte/cli/*.sh', 'egnyte',
             'users list --json {"startIndex":1,"count":100} --fields startIndex,totalResults,resources.id,resources.active,resources.authType,resources.userType',
             {}, json.dumps(EG_USER)),
            ('files-com/cli/*.sh', 'files-cli',
             'users find --id=17 --format json --non-interactive', {'FILES_USER_ID': '17'},
             json.dumps(FILES_USER)),
            ('tresorit/cli/*.sh', 'tresorit-cli', 'status', {}, 'fixture status'),
        ):
            with self.subTest(pack=glob):
                stub = '[[ "$*" == "$EXPECTED_ARGS" ]] || exit 14\nprintf "%s" "$MOCK_BODY"\n'
                result = self.run_pack(glob, cmd, stub,
                                       {**env, 'EXPECTED_ARGS': args, 'MOCK_BODY': output})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn('OMIT', result.stdout)

    def test_files_com_rejects_mismatched_identity(self):
        proc = self.run_pack('files-com/cli/*.sh', 'files-cli', 'printf "%s" "$MOCK_BODY"\n',
                             {'FILES_USER_ID': '18', 'MOCK_BODY': json.dumps(FILES_USER)})
        self.assertEqual(proc.returncode, 2)
        self.assertFalse(proc.stdout)

    def test_sharefile_blocks_non_vendor_host_before_http(self):
        result = self.run_pack('sharefile/api/*.sh', 'curl', 'exit 18\n',
                               {'SHAREFILE_SUBDOMAIN': 'untrusted.example',
                                'SHAREFILE_ACCESS_TOKEN': 'fixture'})
        self.assertEqual(result.returncode, 2)
        self.assertIn('Missing or invalid SHAREFILE_SUBDOMAIN', result.stderr)


if __name__ == '__main__':
    unittest.main()
