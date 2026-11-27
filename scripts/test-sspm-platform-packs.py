"""Offline contract tests for the vendor API and CLI wrappers."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
CASES = (
    ('confluent-cloud/api', 'https://api.confluent.cloud/iam/v2/service-accounts?page_size=100',
     {'CONFLUENT_CLOUD_API_KEY': 'fixture', 'CONFLUENT_CLOUD_API_SECRET': 'fixture'},
     {'data': [{'id': 'sa-synthetic', 'display_name': 'fixture', 'description': 'OMIT'}],
      'metadata': {'next': 'https://api.confluent.cloud/iam/v2/service-accounts?page_token=next'}},
     'accounts'),
    ('contentful/api', 'https://api.eu.contentful.com/organizations/fixture/organization_memberships?limit=100&skip=10',
     {'CONTENTFUL_CMA_TOKEN': 'fixture', 'CONTENTFUL_ORG_ID': 'fixture',
      'CONTENTFUL_REGION': 'eu', 'CONTENTFUL_SKIP': '10'},
     {'total': 11, 'items': [{'sys': {'id': 'member-synthetic', 'status': 'active'},
                             'role': 'member', 'email': 'OMIT'}]},
     'memberships'),
    ('freshdesk/api', 'https://example.freshdesk.com/api/v2/agents?per_page=100&page=2',
     {'FRESHDESK_SUBDOMAIN': 'example', 'FRESHDESK_API_KEY': 'fixture', 'FRESHDESK_PAGE': '2'},
     [{'id': 7, 'role_ids': [1], 'group_ids': [8], 'ticket_scope': 2, 'email': 'OMIT'}],
     'agents'),
)


class Packs(unittest.TestCase):
    def run_pack(self, subdir, name, stub, env):
        pack = next((ROOT / 'packs' / subdir).glob('hth-*.sh'))
        with tempfile.TemporaryDirectory() as tmp:
            binary = Path(tmp) / name
            binary.write_text('#!/bin/bash\nset -eu\n' + stub)
            binary.chmod(0o700)
            return subprocess.run(['bash', str(pack)], capture_output=True, text=True,
                                  env={**os.environ, **env, 'PATH': tmp + os.pathsep + os.environ['PATH']},
                                  check=False)

    def test_api_inventory_filters_outputs_and_stops_on_failures(self):
        for directory, url, variables, data, key in CASES:
            with self.subTest(pack=directory):
                stub = """[[ "$1" = --disable && "${!#}" = "$EXPECTED_URL" ]]
header=$(cat)
[[ "$header" == 'header = "Authorization: '* ]]
[[ "${MOCK_FAIL:-}" != 1 ]]
printf '%s' "$MOCK_BODY"
"""
                env = {**variables, 'EXPECTED_URL': url}
                proc = self.run_pack(directory, 'curl', stub,
                                     {**env, 'MOCK_BODY': json.dumps(data)})
                self.assertEqual(proc.returncode, 0, proc.stderr)
                output = json.loads(proc.stdout)
                self.assertEqual(len(output[key]), 1)
                self.assertNotIn('OMIT', proc.stdout)
                invalid = self.run_pack(directory, 'curl', stub,
                                        {**env, 'MOCK_BODY': json.dumps({'error': True})})
                self.assertEqual(invalid.returncode, 2)
                self.assertFalse(invalid.stdout)
                unavailable = self.run_pack(directory, 'curl', stub,
                                            {**env, 'MOCK_FAIL': '1', 'MOCK_BODY': '{}'})
                self.assertEqual(unavailable.returncode, 2)
                self.assertFalse(unavailable.stdout)

    def test_cli_uses_documented_subcommands(self):
        for directory, command, args, env in (
            ('confluent-cloud/cli', 'confluent', 'iam service-account list', {}),
            ('mulesoft-anypoint/cli', 'anypoint-cli-v4', 'account:environment:list',
             {'ANYPOINT_ORG': 'fixture', 'ANYPOINT_CLIENT_ID': 'fixture',
              'ANYPOINT_CLIENT_SECRET': 'fixture'}),
        ):
            with self.subTest(pack=directory):
                proc = self.run_pack(directory, command, '[[ "$*" = "$EXPECTED_ARGS" ]]\n',
                                     {**env, 'EXPECTED_ARGS': args})
                self.assertEqual(proc.returncode, 0, proc.stderr)

    def test_contentful_security_check_reports_boolean_evidence_only(self):
        stub = """[[ "$1 $2 $3 $4 $5" == 'organization sec-check --organization-id fixture --output-file' ]]
printf '%s' "$MOCK_REPORT" > "$6"
"""
        check_names = ['permission_check', 'sso_enabled', 'sso_enforced',
                       'sso_exempt_users', 'sso_exempt_users_with_mfa_disabled']
        report = {name: {'pass': True, 'data': 'OMIT'} for name in check_names}
        report['sso_exempt_users']['pass'] = False
        env = {'CONTENTFUL_ORG_ID': 'fixture'}
        proc = self.run_pack('contentful/cli', 'contentful', stub,
                             {**env, 'MOCK_REPORT': json.dumps(report)})
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertFalse(json.loads(proc.stdout)['no_exempt_users'])
        self.assertNotIn('OMIT', proc.stdout)
        report['permission_check']['pass'] = False
        proc = self.run_pack('contentful/cli', 'contentful', stub,
                             {**env, 'MOCK_REPORT': json.dumps(report)})
        self.assertEqual(proc.returncode, 2)
        self.assertFalse(proc.stdout)


if __name__ == '__main__':
    unittest.main()
