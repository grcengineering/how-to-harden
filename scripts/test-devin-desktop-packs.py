#!/usr/bin/env python3
"""Offline pack contract tests: fixtures only, no Devin client/account or network.

Run: python3 scripts/test-devin-desktop-packs.py
A synthetic root-owner case exercises the verifier's success branch; it is not
live-device proof. Every real fixture is created in a temporary directory.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / "packs/devin-desktop/config"

def pack(section):
    return next(PACKS.glob(f"hth-devin-desktop-{section}-*"))

def invoke(section, *args):
    return subprocess.run(["bash", str(pack(section)), *map(str, args)],
                          text=True, capture_output=True, timeout=10)

def jsonc(section):
    return json.loads("\n".join(line for line in pack(section).read_text().splitlines()
                               if not line.lstrip().startswith("//")))

class DesktopPacks(unittest.TestCase):
    def test_shell_syntax(self):
        for path in (ROOT / "packs/devin-desktop").rglob("*.sh"):
            with self.subTest(path=path.name):
                result = subprocess.run(["bash", "-n", str(path)], capture_output=True)
                self.assertEqual(result.returncode, 0)

    def test_extension_string_type_and_wildcard_deny(self):
        result = invoke("2.01", "ms-python.python", "github.vscode-pull-request-github")
        self.assertEqual(result.returncode, 0, result.stderr)
        outer = json.loads(result.stdout)
        self.assertIsInstance(outer["AllowedExtensions"], str)
        self.assertEqual(json.loads(outer["AllowedExtensions"]),
                         {"*": False, "ms-python.python": True,
                          "github.vscode-pull-request-github": True})

    def test_extension_invalid_inputs(self):
        for args in [(), ("*",), ("publisher",), ("$(touch /tmp/not-created)",)]:
            with self.subTest(args=args):
                self.assertNotEqual(invoke("2.01", *args).returncode, 0)

    def test_marketplace_valid(self):
        result = invoke("2.02", "https://gallery.example.test/api/v1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout),
                         {"ExtensionGalleryServiceUrl": "https://gallery.example.test/api/v1"})

    def test_marketplace_rejects_unsafe_urls(self):
        for url in ["http://gallery.example.test", "file:///etc/passwd",
                    "https://user:secret@example.test", "https://example.test?q=token",
                    "https://example.test/#fragment", "https://example.test/a b",
                    "https://[broken", "https://example.test:bad", "https://example.test:"]:
            with self.subTest(url=url):
                result = invoke("2.02", url)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Traceback", result.stderr)
                self.assertEqual(result.stdout, "")

    def test_literal_policy_types(self):
        self.assertEqual(jsonc("2.03"), {"UpdateMode": "default"})
        self.assertEqual(jsonc("4.02"), {"TelemetryLevel": "off", "EnableFeedback": False})

    def test_hook_denies_constant_no_payload_execution(self):
        entry = jsonc("1.03")["hooks"]["pre_run_command"][0]
        # This executes only the hard-coded local denial, not user commands or a hook engine.
        result = subprocess.run(["bash", "-c", entry["command"]], input='{}',
                                text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 2)
        self.assertIn("disabled by policy", result.stderr)
        self.assertIn("exit 2", entry["powershell"])
        self.assertTrue(entry["show_output"])

    def test_ignore_emits_without_writing(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(["bash", str(pack("4.01"))], cwd=tmp,
                                    text=True, capture_output=True, timeout=5)
            self.assertEqual(result.returncode, 0)
            self.assertIn(".env.*", result.stdout)
            self.assertIn("*.pem", result.stdout)
            self.assertEqual(list(Path(tmp).iterdir()), [])

    def run_verify(self, expected, actual, fake_owner=False, mode=0o644):
        with tempfile.TemporaryDirectory() as tmp:
            expected_file, policy = Path(tmp)/"expected.json", Path(tmp)/"policy.json"
            expected_file.write_text(expected if isinstance(expected, str) else json.dumps(expected))
            policy.write_text(actual if isinstance(actual, str) else json.dumps(actual))
            policy.chmod(mode)
            before = policy.read_bytes()
            if not fake_owner:
                result = invoke("5.01", "--expected", expected_file, "--policy", policy)
            else:
                # Mock only root ownership, not JSON parsing, permissions, comparison or I/O.
                code = pack("5.01").read_text().split("<<'PYCODE'\n", 1)[1].split("\nPYCODE", 1)[0]
                runner = '''import os, pathlib, sys
from unittest.mock import patch
original = pathlib.Path.stat
def stat_with_root_owner(self, *args, **kwargs):
    result = original(self, *args, **kwargs)
    if str(self) == sys.argv[4]:
        values = list(result); values[4] = 0
        return os.stat_result(values)
    return result
with patch.object(pathlib.Path, "stat", stat_with_root_owner):
    exec(compile(CODE, "embedded-policy-verifier", "exec"))
'''.replace("CODE", repr(code))
                result = subprocess.run(["python3", "-c", runner, "--expected", str(expected_file),
                                         "--policy", str(policy)], text=True, capture_output=True, timeout=5)
            self.assertEqual(policy.read_bytes(), before)
            return result

    def test_verification_success_with_synthetic_root_owner(self):
        expected = {"TelemetryLevel": "off", "EnableFeedback": False,
                    "AllowedExtensions": '{"*":false,"ms-python.python":true}'}
        actual = {**expected, "AllowedExtensions": '{"ms-python.python":true,"*":false}',
                  "UnrelatedPolicy": "preserved"}
        result = self.run_verify(expected, actual, fake_owner=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_verification_detects_drift_and_type_confusion(self):
        for expected, actual in [({"TelemetryLevel":"off"}, {"TelemetryLevel":"all"}),
                                 ({"EnableFeedback":False}, {"EnableFeedback":0}),
                                 ({"AllowedExtensions":'{"*":false}'},
                                  {"AllowedExtensions":'{"*":0}'})]:
            with self.subTest(expected=expected):
                result = self.run_verify(expected, actual, fake_owner=True)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("FAIL:", result.stdout)

    def test_verification_writable_policy_fails(self):
        result = self.run_verify({"TelemetryLevel":"off"}, {"TelemetryLevel":"off"},
                                 fake_owner=True, mode=0o666)
        self.assertEqual(result.returncode, 1)
        self.assertIn("FAIL: root-owned", result.stdout)

    def test_verification_invalid_or_duplicate_json_unknown(self):
        for expected, actual in [("{", {}), ({"TelemetryLevel":"off"}, "{"),
                                 ('{"TelemetryLevel":"off","TelemetryLevel":"all"}', {}),
                                 ({}, {}), ({"Unsupported":"no"}, {}),
                                 ({"AllowedExtensions":{}}, {}),
                                 ({"AllowedExtensions":'{"*":true}'}, {}),
                                 ({"TelemetryLevel":"bogus"}, {})]:
            with self.subTest(expected=expected):
                result = self.run_verify(expected, actual)
                self.assertEqual(result.returncode, 2)
                self.assertIn("UNKNOWN:", result.stderr)
                self.assertNotIn("Traceback", result.stderr)

    def test_verification_missing_and_symlink_unknown(self):
        with tempfile.TemporaryDirectory() as tmp:
            baseline, policy = Path(tmp)/"baseline.json", Path(tmp)/"policy.json"
            baseline.write_text('{"TelemetryLevel":"off"}')
            missing = invoke("5.01", "--expected", baseline, "--policy", policy)
            self.assertEqual(missing.returncode, 2)
            policy.symlink_to(baseline)
            symlink = invoke("5.01", "--expected", baseline, "--policy", policy)
            self.assertEqual(symlink.returncode, 2)

    def test_verifier_does_not_print_other_policy_values(self):
        result = self.run_verify({"TelemetryLevel":"off"},
                                {"TelemetryLevel":"off", "token":"not-a-real-secret"}, fake_owner=True)
        self.assertNotIn("not-a-real-secret", result.stdout + result.stderr)


class DesktopApiPacks(unittest.TestCase):
    key = "cog_OfflineFixtureOnly"
    response = {"models":[{"uid":"reviewed-model","allowed":True,"pricing_dimensions":[]}],
                "allowed_model_uids":["reviewed-model"],"allowed_model_tags":[]}

    def execute(self, section, apply=False, status="200", response=None, key=None, etag='"revision-1"',
                desired=None, snapshot_key=None, snapshot=None):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            shim = root / "curl"
            shim.write_text("""#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
header = sys.stdin.read()
assert args[0] == '--disable'
assert 'Authorization: Bearer cog_' in header
assert not any('cog_' in arg for arg in args)
assert args[args.index('--write-out')+2] == 'https://server.codeium.com/api/v2alpha/models'
record = {'method':args[args.index('--request')+1], 'follows_redirects':'--location' in args}
if '--data-binary' in args:
    record['body'] = json.loads(pathlib.Path(args[args.index('--data-binary')+1][1:]).read_text())
    record['if_match'] = args[args.index('--header',args.index('--header')+1)+1]
pathlib.Path(os.environ['HTH_TEST_CALL']).write_text(json.dumps(record))
pathlib.Path(args[args.index('--dump-header')+1]).write_text('HTTP/1.1 200 OK\\nETag: '+os.environ['HTH_TEST_ETAG']+'\\n')
pathlib.Path(args[args.index('--output')+1]).write_text(os.environ['HTH_TEST_RESPONSE'])
sys.stdout.write(os.environ['HTH_TEST_STATUS'])
""")
            shim.chmod(0o700)
            env = dict(os.environ, PATH=str(root)+os.pathsep+os.environ['PATH'],
                       DEVIN_API_KEY=self.key if key is None else key,
                       HTH_TEST_CALL=str(root/'call.json'), HTH_TEST_STATUS=status,
                       HTH_TEST_ETAG=etag.replace("\x00", ""), HTH_TEST_RESPONSE=json.dumps(self.response if response is None else response))
            path = next((ROOT/'packs/devin-desktop/api').glob('hth-devin-desktop-'+section+'-*'))
            cmd = ['bash',str(path)]
            if section == '4.04':
                want, snap = root/'desired.json',root/'snapshot.json'
                want.write_text(desired if isinstance(desired,str) else json.dumps(desired if desired is not None else {
                    'allowed_model_uids':['reviewed-model'],'allowed_model_tags':[]}))
                snap.write_text(snapshot if isinstance(snapshot,str) else json.dumps({'etag':etag,'credential_fingerprint':hashlib.sha256(
                    (snapshot_key or self.key).encode()).hexdigest()}))
                cmd.extend([str(want),str(snap)])
                if apply: cmd.append('--apply')
            result = subprocess.run(cmd,env=env,text=True,capture_output=True,timeout=10)
            call = json.loads((root/'call.json').read_text()) if (root/'call.json').exists() else None
            self.assertNotIn(self.key,result.stdout+result.stderr)
            return result,call

    def test_read_request_snapshot(self):
        result,call = self.execute('5.02')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(call,{'method':'GET','follows_redirects':False})
        report=json.loads(result.stdout)
        self.assertEqual(report['allowed_models'],['reviewed-model'])
        self.assertEqual(report['etag'],'"revision-1"')
        self.assertNotIn('pricing',result.stdout)

    def test_default_plan_never_calls_api_or_needs_key(self):
        result,call=self.execute('4.04',key='')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIsNone(call)
        self.assertIn('PLAN ONLY',result.stdout)

    def test_apply_mock_uses_etag_and_full_body(self):
        result,call=self.execute('4.04',apply=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(call['method'],'PUT')
        self.assertEqual(call['if_match'],'If-Match: "revision-1"')
        self.assertEqual(call['body'],{'allowed_model_uids':['reviewed-model'],'allowed_model_tags':[]})

    def test_apply_refuses_different_credential_snapshot(self):
        result,call=self.execute('4.04',apply=True,snapshot_key='cog_DifferentCredential')
        self.assertNotEqual(result.returncode,0)
        self.assertIsNone(call)

    def test_http_failures_never_become_secure(self):
        for status in ['301','401','403','412','429','500']:
            with self.subTest(status=status):
                result,call=self.execute('5.02',status=status)
                self.assertEqual(result.returncode,2)
                self.assertIn('UNKNOWN',result.stderr)
                self.assertNotIn('reviewed-model',result.stdout)

    def test_alpha_response_shape_or_etag_unknown(self):
        for response in [{}, {'models':[], 'allowed_model_uids':'wrong','allowed_model_tags':[]}]:
            result,call=self.execute('5.02',response=response)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('UNKNOWN',result.stderr)
        result,call=self.execute('5.02',etag='*')
        self.assertNotEqual(result.returncode,0)

    def test_empty_allowlist_and_wildcard_etag_refused_before_request(self):
        result,call=self.execute('4.04',apply=True,desired={'allowed_model_uids':[],'allowed_model_tags':[]})
        self.assertNotEqual(result.returncode,0)
        self.assertIsNone(call)
        result,call=self.execute('4.04',apply=True,etag='*')
        self.assertNotEqual(result.returncode,0)
        self.assertIsNone(call)

    def test_apply_response_mismatch_is_unknown(self):
        response = {**self.response, 'allowed_model_uids':['unexpected-model']}
        result,call=self.execute('4.04',apply=True,response=response)
        self.assertEqual(result.returncode,2)
        self.assertEqual(call['method'],'PUT')
        self.assertIn('UNKNOWN',result.stderr)

    def test_duplicate_desired_or_snapshot_keys_refused(self):
        desired = '{"allowed_model_uids":["reviewed-model"],"allowed_model_tags":[],"allowed_model_tags":["broad"]}'
        result,call=self.execute('4.04',apply=True,desired=desired)
        self.assertEqual(result.returncode,2)
        self.assertIsNone(call)
        fp=hashlib.sha256(self.key.encode()).hexdigest()
        snapshot='{"etag":"\\"revision-1\\"","credential_fingerprint":"'+fp+'","credential_fingerprint":"'+fp+'"}'
        result,call=self.execute('4.04',apply=True,snapshot=snapshot)
        self.assertEqual(result.returncode,2)
        self.assertIsNone(call)

    def test_control_characters_in_etag_refused(self):
        for etag in ['"revision\t1"','"revision\x001"','"revision\x7f1"']:
            result,call=self.execute('4.04',apply=True,etag=etag)
            self.assertEqual(result.returncode,2)
            self.assertIsNone(call)

    def test_invalid_key_refused_without_request(self):
        for key in ['', 'legacy_key', 'cog_bad\nheader']:
            result,call=self.execute('5.02',key=key)
            self.assertEqual(result.returncode,2)
            self.assertIsNone(call)

if __name__ == "__main__":
    unittest.main(verbosity=2)
