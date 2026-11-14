"""Offline argument/guard checks; never connects to Snowflake."""
import os
import pathlib
import subprocess
import tempfile
import unittest
import re
import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]

class PolicyInspection(unittest.TestCase):
    def test_profile_gate_precedes_connection_or_tool_use(self):
        for script in (ROOT / 'packs/snowflake/cli').glob('hth-snowflake-1.0[56]-*.sh'):
            for level in ('0', '1', '5', 'invalid'):
                with self.subTest(script=script.name, level=level):
                    result = subprocess.run(['bash', str(script)],
                        env=dict(os.environ, HTH_PROFILE_LEVEL=level), capture_output=True, text=True)
                    self.assertEqual(result.returncode, 2)
                    self.assertIn('HTH_PROFILE_LEVEL', result.stderr)

    def test_inspectors(self):
        for section, kind, name in [('1.05', 'AUTHENTICATION', 'inspect-wif-policy'), ('1.06', 'MULTI PARTY APPROVAL', 'inspect-approval-policy')]:
            script = ROOT / f'packs/snowflake/cli/hth-snowflake-{section}-{name}.sh'
            with tempfile.TemporaryDirectory() as td:
                fake = pathlib.Path(td) / 'snow'
                fake.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$HTH_TEST_ARGS"\nexit "${HTH_TEST_EXIT:-0}"\n')
                fake.chmod(0o700)
                args = pathlib.Path(td) / 'args'
                env = dict(os.environ, PATH=f'{td}:/usr/bin:/bin', HTH_SNOW_CONNECTION='test connection', HTH_POLICY='SECURITY_DB.POLICIES.REVIEWED', HTH_TEST_ARGS=str(args), HTH_PROFILE_LEVEL='3')
                run = subprocess.run(['bash', str(script)], env=env, capture_output=True)
                self.assertEqual(run.returncode, 0, run.stderr)
                captured = args.read_text().splitlines()
                self.assertIn(f'DESCRIBE {kind} POLICY SECURITY_DB.POLICIES.REVIEWED;', captured)
                self.assertIn('test connection', captured)
                self.assertIn('NONE', captured)
                args.unlink()
                for invalid in ['X; DROP USER A', 'a.b.c;select 1', 'a.b', 'a.b.c.d', '"a".b.c', 'a.b.c\nDROP USER A']:
                    env['HTH_POLICY'] = invalid
                    self.assertNotEqual(subprocess.run(['bash', str(script)], env=env, capture_output=True).returncode, 0)
                    self.assertFalse(args.exists())
                env['HTH_POLICY'] = 'A.B.C'
                env['HTH_TEST_EXIT'] = '5'
                self.assertEqual(subprocess.run(['bash', str(script)], env=env, capture_output=True).returncode, 5)

    def test_unattached_templates(self):
        for p in (ROOT / 'packs/snowflake/db').glob('hth-snowflake-1.0[56]-*.sql'):
            sql = '\n'.join(line for line in p.read_text().splitlines() if not line.startswith('--'))
            self.assertNotIn('ALTER ACCOUNT', sql)
            self.assertNotIn('OR REPLACE', sql)
            self.assertNotIn('ALTER USER', sql)
        sql = (ROOT / 'packs/snowflake/db/hth-snowflake-1.06-independent-approval.sql').read_text()
        self.assertIn('self_approval_allowed: false', sql)
        self.assertIn('MODIFY_MULTI_PARTY_APPROVAL', sql)
        self.assertIn('required_approvals: 2', sql)
        body = re.search(r'AS \$\$(.*?)\$\$;', sql, re.S).group(1)
        rule = yaml.safe_load(body)['rules'][0]
        self.assertIs(rule['self_approval_allowed'], False)
        self.assertLess(rule['required_approvals'], len(rule['approvers']['users']))
        self.assertEqual(len(rule['operations']), len(set(rule['operations'])))

if __name__ == '__main__':
    unittest.main()
