#!/usr/bin/env python3
"""Offline fixtures for Devin CLI packs. No Devin installation/account required."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/devin-cli'


class DevinCliPacks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.bin = self.work / 'bin'
        self.bin.mkdir()
        self.calls = self.work / 'calls'
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        HTH_CALLS=str(self.calls), HOME=str(self.work))
        for key in ('DEVIN_ENTERPRISE_HOST', 'DEVIN_ACCOUNT_ID', 'DEVIN_PROXY_URL'):
            self.env.pop(key, None)
        self.stub('devin', 'printf "%s\\n" "$*" >> "$HTH_CALLS"\n')
        self.stub('uname', 'printf "%s\\n" "${MOCK_OS:-Linux}"\n')
        self.stub('bwrap', 'exit 0\n')
        self.stub('socat', 'exit 0\n')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/sh\n' + body)
        path.chmod(0o700)

    def run_pack(self, kind, section, *args, env=None):
        files = list((PACKS / kind).glob(f'hth-devin-cli-{section}-*.sh'))
        self.assertEqual(len(files), 1)
        return subprocess.run(['bash', str(files[0]), *args], cwd=self.work,
                              env=self.env if env is None else env,
                              text=True, capture_output=True, timeout=10)

    def recorded(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_all_shell_syntax(self):
        for file in PACKS.rglob('*.sh'):
            with self.subTest(file=file.name):
                result = subprocess.run(['bash', '-n', str(file)], capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_jsonc_templates_have_one_valid_object(self):
        for file in PACKS.rglob('*.jsonc'):
            with self.subTest(file=file.name):
                # These controlled fixtures use full-line comments only; this is
                # NOT a general JSONC parser for arbitrary third-party files.
                text = '\n'.join(line for line in file.read_text().splitlines()
                                 if not line.lstrip().startswith('//'))
                self.assertIsInstance(json.loads(text), dict)

    def test_identity_emit_and_validate(self):
        env = dict(self.env, DEVIN_ENTERPRISE_HOST='example.devinenterprise.com',
                   DEVIN_ACCOUNT_ID='acct-test')
        out = self.run_pack('config', '1.01', 'emit', env=env)
        self.assertEqual(out.returncode, 0, out.stderr)
        data = json.loads(out.stdout)
        self.assertEqual(data['enterprise_host'], env['DEVIN_ENTERPRISE_HOST'])
        self.assertEqual(data['account_id'], 'acct-test')
        self.assertEqual(set(data), {'enterprise_host', 'account_id'})
        path = self.work / 'system.json'
        path.write_text(out.stdout)
        verified = self.run_pack('config', '1.01', 'validate', str(path))
        self.assertEqual(verified.returncode, 0, verified.stderr)
        self.assertIn('NOT deployment', verified.stdout)
        self.assertEqual(self.recorded(), [])

    def test_identity_requires_both_values(self):
        for env in [self.env, dict(self.env, DEVIN_ENTERPRISE_HOST='example.com')]:
            out = self.run_pack('config', '1.01', 'emit', env=env)
            self.assertNotEqual(out.returncode, 0)
            self.assertEqual(out.stdout, '')

    def test_identity_rejects_insecure_or_secret_proxy_values(self):
        for host in ['http://example.com', 'https://example.com', 'example.com/path', '  ']:
            out = self.run_pack('config', '1.01', 'emit', env=dict(
                self.env, DEVIN_ENTERPRISE_HOST=host, DEVIN_ACCOUNT_ID='acct-test'))
            self.assertNotEqual(out.returncode, 0)
        for proxy in ['http://user:SECRET@example.com', 'file:///tmp/proxy',
                      'https://example.com/?token=SECRET', 'https://example.com/#SECRET']:
            out = self.run_pack('config', '1.01', 'emit', env=dict(
                self.env, DEVIN_ENTERPRISE_HOST='example.com', DEVIN_ACCOUNT_ID='acct-test',
                DEVIN_PROXY_URL=proxy))
            self.assertNotEqual(out.returncode, 0)
            self.assertNotIn('SECRET', out.stdout + out.stderr)

    def test_manual_proxy_emission(self):
        out = self.run_pack('config', '1.01', 'emit', env=dict(
            self.env, DEVIN_ENTERPRISE_HOST='example.com', DEVIN_ACCOUNT_ID='acct-test',
            DEVIN_PROXY_URL='https://proxy.example.com:8443'))
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(json.loads(out.stdout)['proxy'],
                         {'mode': 'manual', 'url': 'https://proxy.example.com:8443', 'no_proxy': ''})

    def test_invalid_system_json_and_symlink_rejected(self):
        path = self.work / 'system.json'
        samples = ['{}', '{"enterprise_host":',
                   '{"enterprise_host":"example.com","enterprise_host":"other.com","account_id":"a"}',
                   '{"enterprise_host":"example.com","account_id":"a","unknown":true}',
                   '{"enterprise_host":"example.com","account_id":"a","proxy":{"mode":"manual","url":"https://example.com","no_proxy":[]}}']
        for sample in samples:
            path.write_text(sample)
            out = self.run_pack('config', '1.01', 'validate', str(path))
            self.assertNotEqual(out.returncode, 0)
            self.assertNotIn('Traceback', out.stderr)
        link = self.work / 'link.json'
        link.symlink_to(path)
        self.assertNotEqual(self.run_pack('config', '1.01', 'validate', str(link)).returncode, 0)

    def test_audit_rejects_unmanaged_temp_policy(self):
        path = self.work / 'system.json'
        path.write_text('{"enterprise_host":"example.com","account_id":"a"}')
        path.chmod(0o666)
        out = self.run_pack('config', '1.01', 'audit', str(path))
        self.assertNotEqual(out.returncode, 0)
        self.assertIn('ownership', (out.stderr + out.stdout).lower().replace('owned', 'ownership'))

    def test_auth_inventory_only(self):
        out = self.run_pack('cli', '1.01')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), ['version', 'auth status'])

    def test_sandbox_preflight_is_not_launch(self):
        out = self.run_pack('cli', '2.01')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertIn('untested', out.stdout)
        self.assertEqual(self.recorded(), [])

    def test_sandbox_launch_is_explicit_and_trust_preserving(self):
        out = self.run_pack('cli', '2.01', '--launch')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), ['--sandbox --permission-mode autonomous --respect-workspace-trust true'])

    def test_sandbox_rejects_windows_and_extra_flags(self):
        out = self.run_pack('cli', '2.01', '--launch', env=dict(self.env, MOCK_OS='MINGW64_NT'))
        self.assertNotEqual(out.returncode, 0)
        self.assertEqual(self.recorded(), [])
        out = self.run_pack('cli', '2.01', '--launch', '--permission-mode', 'dangerous')
        self.assertNotEqual(out.returncode, 0)
        self.assertEqual(self.recorded(), [])

    def test_normal_launcher_dry_run_and_explicit_launch(self):
        out = self.run_pack('cli', '2.02')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), [])
        out = self.run_pack('cli', '2.02', '--launch')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), ['--permission-mode normal --respect-workspace-trust true'])

    def test_mcp_default_is_list(self):
        out = self.run_pack('cli', '3.01')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), ['mcp list'])

    def test_mcp_disable_needs_apply_and_valid_scope(self):
        out = self.run_pack('cli', '3.01', 'disable', 'test-server', 'project')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), [])
        out = self.run_pack('cli', '3.01', 'disable', 'test-server', 'project', '--apply')
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), ['mcp disable test-server --scope project'])
        self.calls.unlink()
        for args in [('disable', '--evil', 'user', '--apply'),
                     ('disable', 'test', 'global', '--apply'),
                     ('disable', 'test', 'user', '--yes'),
                     ('disable', 'test;echo-secret', 'local', '--apply')]:
            out = self.run_pack('cli', '3.01', *args)
            self.assertNotEqual(out.returncode, 0)
            self.assertEqual(self.recorded(), [])

    def test_effective_inventories_do_not_install(self):
        for section in ('3.02', '5.01'):
            out = self.run_pack('cli', section)
            self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(self.recorded(), ['rules list', 'skills list', 'plugins list'])

    def test_all_pack_anchors_resolve_to_control_headings(self):
        guide = (ROOT / 'docs/_guides/devin-cli.md').read_text()
        heads = {re.sub(r'[^a-z0-9 -]', '', h.lower()).replace(' ', '-')
                 for h in re.findall(r'^### (.+)$', guide, re.M)}
        for path in PACKS.rglob('hth-*'):
            with self.subTest(file=path.name):
                anchor = re.search(r'^.*guide: https://howtoharden.com/guides/devin-cli/#(.+)$',
                                   path.read_text(), re.M).group(1)
                self.assertIn(anchor, heads)


if __name__ == '__main__':
    unittest.main(verbosity=2)
