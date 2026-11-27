"""Offline request, evidence scope, and failure checks for SSPM packs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SpecialtyPacks(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.tmp = Path(tmp.name)
        self.request = self.tmp / "request"
        self.stub("curl", 'cat > "$MOCK_REQUEST"')
        self.stub("dig", ': > "$MOCK_REQUEST"')
        self.env = {
            **os.environ,
            "PATH": f"{self.tmp}:{os.environ['PATH']}",
            "MOCK_REQUEST": str(self.request),
            "ARCGIS_ONLINE_TENANT": "acme",
            "ARCGIS_ONLINE_EXPECTED_ORG_ID": "Ab123",
            "ARCGIS_ONLINE_OAUTH_TOKEN": "local-fixture",
            "BIRD_EMAIL_REGION": "eu1",
            "BIRD_EXPECTED_WORKSPACE_ID": "ws_123",
            "BIRD_EXPECTED_SENDING_DOMAIN": "acme.example",
            "BIRD_EMAIL_DOMAIN_ID": "dom_abc",
            "BIRD_EMAIL_READ_KEY": "bk_eu1_local-fixture",
            "BLUESHIFT_FROM_DOMAIN": "news.acme.example",
        }

    def stub(self, name, first_line):
        path = self.tmp / name
        path.write_text(
            f'#!/usr/bin/env bash\nset -eu\n{first_line}\n'
            'printf "%s\\n" "$@" >> "$MOCK_REQUEST"\n'
            '[[ ${MOCK_FAIL:-0} == 0 ]] || exit 3\n'
            'printf "%s\\n" "$MOCK_RESPONSE"\n'
        )
        path.chmod(0o755)

    def run_pack(self, name, payload=None, **override):
        pack, = (ROOT / "packs" / name).glob("*/*.sh")
        mock = payload if isinstance(payload, str) else json.dumps(payload)
        return subprocess.run(
            [str(pack)], env={**self.env, "MOCK_RESPONSE": mock, **override},
            text=True, capture_output=True, check=False, timeout=15
        )

    def assert_request(self, token, url):
        lines = self.request.read_text().splitlines()
        self.assertEqual(lines[0], f"Authorization: Bearer {token}")
        self.assertEqual(lines[1], "-q")
        self.assertEqual(lines[-1], url)
        self.assertIn("@-", lines)
        self.assertNotIn("--location", lines)
        self.assertNotIn(token, lines[1:])

    def test_arcgis_privacy_requires_both_flags(self):
        expected = {"id": "Ab123", "access": "private", "canSharePublic": False,
                    "user": {"email": "omit-me"}}
        result = self.run_pack("arcgis-online", expected)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("omit-me", result.stdout)
        self.assert_request("local-fixture",
                            "https://acme.maps.arcgis.com/sharing/rest/portals/self?f=json")
        for delta in ({"access": "public"}, {"canSharePublic": True},
                      {"canSharePublic": "false"}, {"user": None},
                      {"id": "other"}, {"error": {"code": 498}}):
            with self.subTest(delta=delta):
                self.assertNotEqual(self.run_pack("arcgis-online", expected | delta).returncode, 0)

    def test_bird_read_claim_is_limited_to_the_exact_verified_domain(self):
        expected = {"id": "dom_abc", "workspace_id": "ws_123", "domain": "acme.example",
                    "status": "verified", "capabilities": {"sending": {"status": "verified"}},
                    "dns_records": ["omit-me"]}
        result = self.run_pack("bird-email", expected)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("omit-me", result.stdout)
        self.assert_request("bk_eu1_local-fixture",
                            "https://eu1.platform.bird.com/v1/email/domains/dom_abc")
        for delta in ({"workspace_id": "ws_override"}, {"domain": "other.example"},
                      {"status": "failed"}, {"capabilities": {"sending": {"status": "warning"}}},
                      {"status": None}, {"capabilities": {}}):
            with self.subTest(delta=delta):
                self.assertNotEqual(self.run_pack("bird-email", expected | delta).returncode, 0)

    def test_invalid_request_scope_fails_before_network(self):
        for app, env in (("arcgis-online", {"ARCGIS_ONLINE_TENANT": "evil.example/x"}),
                         ("arcgis-online", {"ARCGIS_ONLINE_OAUTH_TOKEN": "x\r\nOther: y"}),
                         ("bird-email", {"BIRD_EMAIL_REGION": "us1"}),
                         ("blueshift", {"BLUESHIFT_FROM_DOMAIN": "@malicious.example"})):
            with self.subTest(app=app, env=env):
                self.assertNotEqual(self.run_pack(app, **env).returncode, 0)
                self.assertFalse(self.request.exists())

    def test_endpoint_failure_is_not_posture_evidence(self):
        for app in ("arcgis-online", "bird-email", "blueshift"):
            with self.subTest(app=app):
                result = self.run_pack(app, MOCK_FAIL="1")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")

    def test_dmarc_requires_exact_owner_and_full_enforcement(self):
        prefix = "_dmarc.news.acme.example. 60 IN TXT "
        valid = prefix + '"v=DMARC1; " "p=reject; pct=100;"'
        result = self.run_pack("blueshift", valid)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["policy"], "reject")
        self.assertEqual(self.request.read_text().splitlines()[-2:],
                         ["_dmarc.news.acme.example.", "TXT"])
        for bad in ("", valid + "\n" + valid, valid.replace("reject", "none"),
                    valid.replace("100", "20"), valid.replace("news.", ""),
                    valid.replace('p=reject;', 'p=reject; p=none;'), valid.replace("TXT", "CNAME")):
            with self.subTest(bad=bad):
                self.assertNotEqual(self.run_pack("blueshift", bad).returncode, 0)


if __name__ == "__main__":
    unittest.main()
