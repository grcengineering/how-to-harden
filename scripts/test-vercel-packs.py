#!/usr/bin/env python3
"""Offline regression tests. Only stubbed vendor commands, never tenant access."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / 'packs/vercel'

class Packs(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.cwd = Path(self.tmp.name)
        self.bin = self.cwd / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}',
                        VERCEL_TOKEN='fixture-token', VERCEL_TEAM_ID='team_fixture',
                        VERCEL_PROJECT_ID='prj_fixture', CALLS=str(self.cwd / 'calls'))
        for k in list(self.env):
            if k.startswith('HTH_') or k == 'CRON_SECRET': self.env.pop(k)
        self.stub('vercel', '''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['CALLS'], 'a') as f: f.write(' '.join(sys.argv[1:])+'\\n')
if 'create' in sys.argv:
 print(json.dumps({'hook': {'id':'new', 'url':'https://api.vercel.com/v1/integrations/deploy/prj_fixture/SECRETURL'}}))
elif 'check' in sys.argv: print(json.dumps({'report': {'status':'fail'}}))
elif 'vulnerabilities' in sys.argv: print(json.dumps({'vulnerabilities': [], 'pagination': {'next': None}}))
else: print(json.dumps({'hooks': []}))
''')
        self.stub('curl', '#!/bin/sh\necho "$*" >> "$CALLS"\nprintf "${HTTP_CODE:-401}"\n')
        self.stub('git', '#!/bin/sh\nexit 1\n')

    def stub(self, name, body):
        p = self.bin / name
        p.write_text(body)
        p.chmod(0o755)

    def run_pack(self, pattern, *args, **env):
        path = next(PACKS.glob(pattern))
        return subprocess.run(['bash', str(path), *args], cwd=self.cwd,
                              env=dict(self.env, **env), text=True, capture_output=True)

    def calls(self):
        p = self.cwd / 'calls'
        return p.read_text() if p.exists() else ''

    def test_shell_syntax(self):
        for p in PACKS.rglob('*.sh'):
            r = subprocess.run(['bash', '-n', str(p)], capture_output=True)
            self.assertEqual(r.returncode, 0, str(p))

    def test_secret_scan_never_prints_value(self):
        (self.cwd / '.env.local').write_text('NEXT_PUBLIC_API_KEY=TOPSECRET_FIXTURE\n')
        r = self.run_pack('config/*6.04*')
        self.assertEqual(r.returncode, 1, r.stderr)
        self.assertIn('NEXT_PUBLIC_API_KEY', r.stdout)
        self.assertNotIn('TOPSECRET_FIXTURE', r.stdout + r.stderr)

    def create_hook(self, path):
        return self.run_pack('cli/*6.03*', HTH_HOOK_ID='old', HTH_HOOK_NAME='replacement',
                             HTH_HOOK_REF='main', HTH_HOOK_URL_FILE=str(path))

    def test_hook_create_preserves_old_and_private_file(self):
        path = self.cwd / 'hook-url'
        r = self.create_hook(path)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn('delete', self.calls())
        self.assertNotIn('SECRETURL', r.stdout + r.stderr)
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertIn('SECRETURL', path.read_text())
        self.assertIn('--git-branch main', self.calls())

    def test_hook_refuses_existing_and_symlink_before_create(self):
        target = self.cwd / 'existing'
        target.write_text('preserve')
        link = self.cwd / 'link'
        link.symlink_to(target)
        for path in (target, link):
            r = self.create_hook(path)
            self.assertNotEqual(r.returncode, 0)
            self.assertNotIn('create', self.calls())
            self.assertEqual(target.read_text(), 'preserve')

    def test_hook_retirement_requires_cutover(self):
        r = self.run_pack('cli/*6.03*', HTH_RETIRE_HOOK_ID='old')
        self.assertEqual(r.returncode, 2)
        self.assertNotIn('delete', self.calls())
        r = self.run_pack('cli/*6.03*', HTH_RETIRE_HOOK_ID='old', HTH_CONFIRM_CUTOVER='1')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('delete old', self.calls())

    def test_cron_does_not_execute_authenticated_by_default(self):
        r = self.run_pack('cli/*8.03*', 'example.com', CRON_SECRET='NEVER_SEND')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn('Authorization', self.calls())

    def test_cron_validates_before_write(self):
        r = self.run_pack('cli/*8.03*', 'user:pass@example.com', HTH_CONFIRM_ENV_WRITE='1')
        self.assertEqual(r.returncode, 2)
        self.assertEqual(self.calls(), '')

    def test_cron_unreachable_is_unchecked(self):
        r = self.run_pack('cli/*8.03*', 'example.com', HTTP_CODE='000')
        self.assertEqual(r.returncode, 2)

    def test_patch_gate_precedes_any_network_or_mutation(self):
        p = self.cwd / 'node_modules/next'
        p.mkdir(parents=True)
        for version, code in [('16.4.4', 1), ('15.5.28', 1), ('16.4.5-canary.1', 2), ('16.4.5', 0), ('15.5.29', 0)]:
            (p / 'package.json').write_text(json.dumps({'version':version}))
            r = self.run_pack('api/*9.01*')
            self.assertEqual(r.returncode, code, r.stdout+r.stderr)
            self.assertEqual(self.calls(), '')

    def test_reports_are_private_not_compliance_passes(self):
        for pattern in ('cli/*1.06*', 'cli/*8.05*'):
            r = self.run_pack(pattern, TMPDIR=str(self.cwd))
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertNotIn('"status"', r.stdout)
        for p in self.cwd.rglob('*.json'):
            self.assertEqual(p.stat().st_mode & 0o777, 0o600)

    def test_security_review_pagination_and_fail_closed(self):
        self.stub('vercel', r'''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['CALLS'], 'a') as f: f.write(' '.join(sys.argv[1:])+'\n')
mode=os.environ['MODE']
if mode == 'error': print(json.dumps({'error': 'denied', 'pagination': {}}))
elif mode == 'missing': print(json.dumps({'pagination': {}}))
else: print(json.dumps({'vulnerabilities': [], 'pagination': {'next': 'cursor' if mode == 'repeat' or '--next' not in sys.argv else None}}))
''')
        for mode, success in [('pages', True), ('repeat', False), ('error', False), ('missing', False)]:
            (self.cwd / 'calls').write_text('')
            r = self.run_pack('cli/*8.05*', MODE=mode, TMPDIR=str(self.cwd))
            self.assertEqual(r.returncode == 0, success, r.stdout+r.stderr)
            if mode == 'pages': self.assertIn('--next cursor', self.calls())

    def test_firewall_refuses_invalid_read_or_write_responses(self):
        p = self.cwd / 'node_modules/next'
        p.mkdir(parents=True)
        (p / 'package.json').write_text('{"version":"16.4.5"}')
        self.stub('curl', "#!/bin/sh\necho \"$*\" >> \"$CALLS\"\ncase \"$*\" in *PATCH*) printf '%s' \"$WRITE_BODY\";; *) printf '%s' \"$READ_BODY\";; esac\n")
        for body in ('', '{}', '{"error":{}}', 'invalid'):
            (self.cwd / 'calls').write_text('')
            r = self.run_pack('api/*9.01*', HTH_APPLY_WAF_RULE='1', READ_BODY=body, WRITE_BODY='{}')
            self.assertEqual(r.returncode, 2, r.stdout+r.stderr)
            self.assertNotIn('PATCH', self.calls())
        for body in ('', '{}', '{"error":{}}', 'invalid'):
            r = self.run_pack('api/*9.01*', HTH_APPLY_WAF_RULE='1', READ_BODY='{"rules":[]}', WRITE_BODY=body)
            self.assertEqual(r.returncode, 2, r.stdout+r.stderr)

    def test_drain_receiver_signatures_and_body_limit(self):
        source = next(PACKS.glob('api/*8.04*')).read_text().split("<<'JS'\n", 1)[1].split('\nJS\n', 1)[0]
        harness = r'''const vm = require('node:vm');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
let handler;
const source = JSON.parse(process.argv[1]);
vm.runInNewContext(source, {
  require: n => n === 'node:http' ? { createServer: fn => {
    handler = fn; return { listen: () => {} };
  }} : crypto,
  process: { env: { VERCEL_DRAIN_SECRET: 'fixture' }, stdout: { write: () => {} } },
  console: { log: () => {}, error: () => {} }, Buffer
});
function request(body, signature, expected) {
  const events = {}; let status;
  const req = { method: 'POST', headers: { 'x-vercel-signature': signature }, on: (e, fn) => { events[e] = fn; } };
  const res = { writeHead: n => { status = n; return res; }, end: () => {} };
  handler(req, res); events.data(body); events.end(); assert.equal(status, expected);
}
const body = Buffer.from('{"test":true}');
request(body, crypto.createHmac('sha1', 'fixture').update(body).digest('hex'), 200);
request(body, 'wrong', 401);
request(body, undefined, 401);
request(Buffer.alloc(1024 * 1024 + 1), 'wrong', 413);
'''
        r = subprocess.run(['node', '-e', harness, json.dumps(source)], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)

if __name__ == '__main__':
    unittest.main(verbosity=2)
