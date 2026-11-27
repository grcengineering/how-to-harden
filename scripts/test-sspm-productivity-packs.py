"""Offline contract checks for four scoped SSPM evidence packs."""
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[1]


class ProductivityPacks(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.tmp = Path(temporary.name)
        self.request = self.tmp / "request"
        curl = self.tmp / "curl"
        curl.write_text(
            '#!/usr/bin/env bash\nset -eu\n'
            'cat > "$MOCK_REQUEST"\nprintf "%s\\n" "$@" >> "$MOCK_REQUEST"\n'
            'if [[ ${MOCK_DENIED:-0} == 1 ]]; then exit 22; fi\n'
            'printf "%s\\n" "$MOCK_RESPONSE"\n'
        )
        curl.chmod(0o755)
        self.env = {
            **os.environ,
            "PATH": f"{self.tmp}:{os.environ['PATH']}",
            "MOCK_REQUEST": str(self.request),
            "FEATUREOS_OAUTH_TOKEN": "test-only-opaque",
            "FEATUREOS_EXPECTED_ORG_ID": "88",
            "FEATUREOS_EXPECTED_ACTOR_ID": "4521",
            "FEATUREOS_EXPECTED_ACTOR_MODE": "app",
            "FRONT_OAUTH_TOKEN": "test-only-opaque",
            "FRONT_TEAMMATE_ID": "tea_123",
            "FRONT_EXPECTED_BLOCKED": "true",
        }

    def run_pack(self, product, response=None, **override):
        file, = (ROOT / "packs" / product).glob("*/*.sh")
        return subprocess.run(
            [str(file)], env={
                **self.env, "MOCK_RESPONSE": json.dumps(response), **override
            }, capture_output=True, text=True, check=False, timeout=15
        )

    def check_request(self, url):
        lines = self.request.read_text().splitlines()
        self.assertEqual(lines[0], "Authorization: Bearer test-only-opaque")
        self.assertEqual(lines[1], "-q")
        self.assertEqual(lines[-1], url)
        self.assertIn("@-", lines)
        self.assertNotIn("--location", lines)
        self.assertNotIn("test-only-opaque", lines[1:])

    def write_plist(self, data, fmt=plistlib.FMT_XML):
        file = self.tmp / "policy.plist"
        file.write_bytes(plistlib.dumps(data, fmt=fmt))
        return str(file)

    def test_featureos_binding(self):
        response = {"success": True, "user": {"id": 4521, "email": "omit-me"},
                    "organization": {"id": 88}, "actor": "app"}
        result = self.run_pack("featureos", response)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["actor_id"], 4521)
        self.assertNotIn("omit-me", result.stdout)
        self.check_request("https://api.featureos.app/api/v3/session_info")
        for wrong in ({"actor": "self"}, {"organization": {"id": 99}},
                      {"user": {"id": "4521"}}, {"success": False}):
            with self.subTest(wrong=wrong):
                self.assertNotEqual(
                    self.run_pack("featureos", response | wrong).returncode, 0
                )

    def test_front_blocked_and_unavailable_are_distinct(self):
        response = {"id": "tea_123", "is_blocked": True, "is_available": False,
                    "email": "omit-me"}
        result = self.run_pack("front", response)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout),
                         {"id": "tea_123", "is_blocked": True, "matches": True})
        self.check_request("https://api2.frontapp.com/teammates/tea_123")
        for wrong in ({"is_blocked": False}, {"is_blocked": None},
                      {"is_blocked": "true"}, {"id": "tea_456"}):
            with self.subTest(wrong=wrong):
                self.assertNotEqual(
                    self.run_pack("front", response | wrong).returncode, 0
                )

    def test_front_accepts_explicit_unblocked_expectation(self):
        result = self.run_pack("front", {"id": "tea_123", "is_blocked": False},
                               FRONT_EXPECTED_BLOCKED="false")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_bad_id_or_header_cannot_trigger_request(self):
        for product, override in (
            ("front", {"FRONT_TEAMMATE_ID": "../anything"}),
            ("front", {"FRONT_OAUTH_TOKEN": "test\r\nX-Injected: bad"}),
            ("featureos", {"FEATUREOS_EXPECTED_ACTOR_MODE": "any"}),
        ):
            with self.subTest(product=product, override=override):
                self.assertNotEqual(self.run_pack(product, **override).returncode, 0)
                self.assertFalse(self.request.exists())

    def test_network_failure_does_not_become_posture_evidence(self):
        for product in ("front", "featureos"):
            with self.subTest(product=product):
                result = self.run_pack(product, MOCK_DENIED="1")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")

    def test_grammarly_native_xml_and_binary_inputs(self):
        token = str(uuid.uuid4())  # Synthetic enrollment fixture, not a provisioned token.
        for fmt in (plistlib.FMT_XML, plistlib.FMT_BINARY):
            file = self.write_plist({"GrammarlyEnrollmentToken": token}, fmt)
            result = self.run_pack("grammarly", GRAMMARLY_MANAGED_PLIST=file)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn(token, result.stdout + result.stderr)
        file = self.write_plist({"GrammarlyEnrollmentToken": "invalid-not-echoed"})
        result = self.run_pack("grammarly", GRAMMARLY_MANAGED_PLIST=file)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("invalid-not-echoed", result.stdout + result.stderr)

    def test_textexpander_policy_needs_two_explicit_booleans(self):
        for route, value in (("vendor", True), ("mdm", False)):
            file = self.write_plist({"SUEnableAutomaticChecks": value,
                                     "SUEnableAutomaticDownload": value})
            result = self.run_pack("textexpander", TEXTEXPANDER_UPDATE_PLIST=file,
                                   TEXTEXPANDER_UPDATE_ROUTE=route)
            self.assertEqual(result.returncode, 0, result.stderr)
        for payload in (
            {"SUEnableAutomaticChecks": True},
            {"SUEnableAutomaticChecks": True, "SUEnableAutomaticDownload": False},
            {"SUEnableAutomaticChecks": "true", "SUEnableAutomaticDownload": True},
        ):
            with self.subTest(payload=payload):
                file = self.write_plist(payload)
                result = self.run_pack("textexpander", TEXTEXPANDER_UPDATE_PLIST=file,
                                       TEXTEXPANDER_UPDATE_ROUTE="vendor")
                self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
