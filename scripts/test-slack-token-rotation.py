#!/usr/bin/env python3
"""Offline subprocess fixtures only; no Slack requests or credentials."""
import json, os, pathlib, subprocess, tempfile, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
API = ROOT / 'packs/slack/api/hth-slack-3.04-read-token-rotation.sh'
CLI = ROOT / 'packs/slack/cli/hth-slack-3.04-read-remote-manifest.sh'

class RotationTests(unittest.TestCase):
    def run_api(self, value, expected, curl_exit=0):
        with tempfile.TemporaryDirectory() as d:
            p = pathlib.Path(d)
            (p/'curl').write_text('#!/usr/bin/env python3\nimport os,sys\nargs=sys.argv[1:]\nassert args[0] == "-q"\nassert "fixture-secret" not in " ".join(args)\nassert "--location" not in args and "-L" not in args\nassert args[-1]=="https://slack.com/api/apps.manifest.export"\nassert "Authorization: Bearer fixture-secret" in sys.stdin.read()\nprint(os.environ["FIXTURE"])\nsys.exit(int(os.environ["CURL_EXIT"]))\n')
            (p/'curl').chmod(0o755)
            env = dict(os.environ, PATH=d+':'+os.environ['PATH'], SLACK_CONFIG_TOKEN='fixture-secret', SLACK_APP_ID='A123', HTH_PROFILE_LEVEL='2', FIXTURE=json.dumps(value), CURL_EXIT=str(curl_exit))
            r = subprocess.run(['bash',str(API)], env=env, capture_output=True,text=True)
            self.assertEqual(r.returncode,expected,r.stderr)
            self.assertNotIn('fixture-secret',r.stdout+r.stderr)
    def test_enabled(self): self.run_api({'ok':True,'manifest':{'settings':{'token_rotation_enabled':True}}},0)
    def test_disabled(self): self.run_api({'ok':True,'manifest':{'settings':{'token_rotation_enabled':False}}},1)
    def test_missing(self): self.run_api({'ok':True,'manifest':{}},2)
    def test_wrong_type(self): self.run_api({'ok':True,'manifest':{'settings':{'token_rotation_enabled':'true'}}},2)
    def test_api_error(self): self.run_api({'ok':False,'error':'invalid_auth'},2)
    def test_http_error(self): self.run_api({},2,22)
    def test_cli(self):
        with tempfile.TemporaryDirectory() as d:
            p=pathlib.Path(d)/'slack';p.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n');p.chmod(0o755)
            r=subprocess.run(['bash',str(CLI)],env=dict(os.environ,PATH=d+':'+os.environ['PATH'],SLACK_APP_ID='A123',HTH_PROFILE_LEVEL='2'),capture_output=True,text=True)
            self.assertEqual(r.returncode,0)
            self.assertEqual(r.stdout.splitlines(),['manifest','--source','remote','--app','A123','--no-color','--skip-update'])
    def test_fragment(self):
        import yaml
        f=ROOT/'packs/slack/config/hth-slack-3.04-token-rotation.yml'
        self.assertIs(yaml.safe_load(f.read_text())['settings']['token_rotation_enabled'],True)
    def test_profile_gate_precedes_credentials_and_vendor_tools(self):
        for script in (API, CLI):
            for level in ('0', '1', '5', 'invalid'):
                with self.subTest(script=script.name, level=level):
                    r = subprocess.run(['bash', str(script)],
                        env=dict(os.environ, HTH_PROFILE_LEVEL=level), capture_output=True, text=True)
                    self.assertEqual(r.returncode, 2)
                    self.assertIn('HTH_PROFILE_LEVEL', r.stderr)
if __name__=='__main__': unittest.main()
