#!/usr/bin/env python3
"""Offline regression tests; never access a tenant or run third-party plugins."""
import json, os, re, subprocess, tempfile, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/anthropic-claude'
def excerpt(name, region):
    s = (PACKS / name).read_text().split('HTH Guide Excerpt: begin '+region, 1)[1].split('HTH Guide Excerpt: end '+region, 1)[0]
    return json.loads('\n'.join(line for line in s.splitlines() if not line.lstrip().startswith('//')))
class PlutoAnthropic(unittest.TestCase):
    def test_strict_hooks_are_really_disabled(self):
        x = excerpt('config/hth-anthropic-claude-7.06-hooks-plugins.jsonc', 'hooks-plugins-maximum')
        self.assertIs(x['disableAllHooks'], True)
        self.assertEqual(x['strictKnownMarketplaces'], [])
        self.assertTrue(x['allowManagedPermissionRulesOnly'])
    def test_vault_scope_and_injection_are_independent(self):
        x = excerpt('config/hth-anthropic-claude-4.02-managed-agents.jsonc', 'managed-agent-vault-header-only')['auth']
        self.assertEqual(x['injection_location'], {'header':True, 'body':False})
        self.assertEqual(x['networking'], {'type':'limited','allowed_hosts':['api.example.com']})
        self.assertEqual(x['secret_value'], 'REPLACE_VIA_APPROVED_SECRET_CHANNEL')
    def test_environment_without_packages_remains_restricted(self):
        x = excerpt('config/hth-anthropic-claude-4.02-managed-agents.jsonc', 'managed-agent-limited-environment')['config']
        self.assertNotIn('packages', x)
        self.assertFalse(x['networking']['allow_package_managers'])
    def test_cli_strict_validation_and_failure_propagation(self):
        script=PACKS/'cli/hth-anthropic-claude-7.06-validate-plugin.sh'
        with tempfile.TemporaryDirectory() as d:
            p=Path(d); plugin=p/'reviewed plugin'; plugin.mkdir()
            mock=p/'claude'; mock.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$CAPTURE"\nexit "${MOCK_RC:-0}"\n'); mock.chmod(0o700)
            env={**os.environ,'PATH':d+':'+os.environ['PATH'],'CAPTURE':str(p/'args')}
            for rc in (0,1):
                result=subprocess.run(['bash',str(script),str(plugin)],env={**env,'MOCK_RC':str(rc)},capture_output=True)
                self.assertEqual(result.returncode,rc)
                self.assertEqual((p/'args').read_text().splitlines(),['plugin','validate',str(plugin.resolve()),'--strict'])
            self.assertEqual(subprocess.run(['bash',str(script)],env=env,capture_output=True).returncode,2)
    def test_guide_boundaries(self):
        code=(ROOT/'docs/_guides/claude-code.md').read_text()
        enterprise=(ROOT/'docs/_guides/claude-enterprise.md').read_text()
        self.assertIn('v2.1.282+',code)
        self.assertIn('Agent SDK callbacks',code)
        self.assertIn('Email invitations outside your organization',enterprise)
        self.assertIn('except individual exceptions',enterprise)
        self.assertIn('**beta**',enterprise)
if __name__ == '__main__': unittest.main()
