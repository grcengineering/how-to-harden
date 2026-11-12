#!/usr/bin/env python3
"""Offline native n8n environment serialization and CLI boundaries."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import yaml
ROOT = Path(__file__).resolve().parents[1]
class NativeN8n(unittest.TestCase):
    def test_environment_mappings_preserve_strings(self):
        files = list((ROOT / 'packs/n8n/config').glob('*.yml'))
        self.assertEqual(len(files), 5)
        values = {}
        for path in files:
            data = yaml.safe_load(path.read_text())
            self.assertEqual(set(data), {'environment'})
            self.assertTrue(all(isinstance(v, str) for v in data['environment'].values()))
            values.update(data['environment'])
        self.assertEqual(values['NODES_EXCLUDE'], '["n8n-nodes-base.executeCommand","n8n-nodes-base.readWriteFile"]')
        self.assertEqual(values['N8N_SSRF_PROTECTION_ENABLED'], 'true')
        self.assertEqual(values['EXECUTIONS_DATA_MAX_AGE'], '336')
    def test_audit_is_read_only_and_preserves_exit_status(self):
        with tempfile.TemporaryDirectory() as temp:
            stub = Path(temp) / 'n8n'
            stub.write_text('#!/bin/sh\nprintf "%s\\n" "$*"\nexit 7\n')
            stub.chmod(0o755)
            env = dict(os.environ, PATH=temp + ':' + os.environ['PATH'], HTH_PROFILE_LEVEL='1')
            result = subprocess.run(['bash', str(ROOT / 'packs/n8n/cli/hth-n8n-3.03-security-audit.sh')], env=env, capture_output=True, text=True)
            self.assertEqual(result.stdout.strip(), 'audit')
            self.assertEqual(result.returncode, 7)
            env['HTH_PROFILE_LEVEL'] = 'bad'
            result = subprocess.run(['bash', str(ROOT / 'packs/n8n/cli/hth-n8n-3.03-security-audit.sh')], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, '')
if __name__ == '__main__':
    unittest.main()
