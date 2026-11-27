"""Test backup and workflow hardening packs with local evidence only."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENV = {
    "DRUVA_GLOBAL_ID": "customer-test", "DRUVA_API_TOKEN": "opaque-fixture",
    "UIPATH_ORGANIZATION_NAME": "org-test", "UIPATH_AUDIT_TOKEN": "opaque-fixture",
}


class FourthDevPacks(unittest.TestCase):
    def run_pack(self, vendor, fixture=None, url=None, **env):
        pack, = (ROOT / "packs" / vendor).glob("*/hth-*.sh")
        with tempfile.TemporaryDirectory() as tmp:
            curl = Path(tmp) / "curl"
            curl.write_text(
                '#!/bin/bash\n[[ "$1" == -q && "${@: -1}" == "$MOCK_URL" ]] || exit 81\n'
                '[[ "$*" != *opaque-fixture* && "$*" != *--location* ]] || exit 82\n'
                'grep -q "Authorization: Bearer opaque-fixture" || exit 83\n'
                'printf "%s" "$MOCK_FIXTURE"\n'
            )
            curl.chmod(0o755)
            return subprocess.run(
                ["bash", str(pack)], capture_output=True, text=True, check=False, timeout=5,
                env={**ENV, "PATH": f"{tmp}:{os.environ['PATH']}", "MOCK_URL": url or "",
                     "MOCK_FIXTURE": json.dumps(fixture), **env},
            )

    def test_druva_count_summary_never_prints_raw_details(self):
        url = "https://apis.druva.com/platform/eventmanagement/v3/events?pageSize=25"
        row = {"globalID": "customer-test", "category": "AUDIT", "details": {"email": "private-value"}}
        result = self.run_pack("druva", {"events": [row, row], "nextPageToken": "private-page"}, url)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["byCategory"], {"AUDIT": 2})
        self.assertNotIn("private", result.stdout)
        self.assertNotIn("customer-test", result.stdout)
        self.assertNotEqual(self.run_pack("druva", {"events": [row] * 26}, url).returncode, 0)

    def test_druva_wrong_customer_rejected(self):
        url = "https://apis.druva.com/platform/eventmanagement/v3/events?pageSize=25"
        result = self.run_pack("druva", {"events": [{"globalID": "wrong", "category": "AUDIT"}]}, url)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_uipath_unified_org_metadata_and_nonredirect(self):
        url = "https://cloud.uipath.com/org-test/orgaudit_/api/query/events?maxCount=25"
        event = {"createdOn": "2026-01-01", "eventType": "Login", "status": 1, "eventSource": "Identity",
                 "actorEmail": "private-value", "eventDetails": "private-value"}
        result = self.run_pack("uipath-automation-cloud",
                               {"auditEvents": [event], "next": "https://example.test"}, url)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["events"][0]["status"], 1)
        self.assertNotIn("private-value", result.stdout)
        self.assertNotEqual(self.run_pack("uipath-automation-cloud", {"results": [event]}, url).returncode, 0)

    def test_uipath_rejects_unsafe_slug(self):
        self.assertEqual(self.run_pack("uipath-automation-cloud", UIPATH_ORGANIZATION_NAME="../").returncode, 2)

    def idrive(self, sample):
        with tempfile.TemporaryDirectory() as tmp:
            export = Path(tmp) / "export.csv"
            export.write_text(sample)
            return self.run_pack("idrive", IDRIVE_REPORT_CSV=str(export),
                                 IDRIVE_STATUS_COLUMN="Status", IDRIVE_APPROVED_STATUS="Successful")

    def test_idrive_counts_quoted_fields_without_outputting_user_data(self):
        result = self.idrive('\ufeffDevice,Status\n"private, workstation",Successful\nprivate,Failed\nprivate,\n')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"scope": "export-only", "rows": 3,
                                                     "approvedStatus": 1, "otherStatus": 1, "missingStatus": 1})
        self.assertNotIn("private", result.stdout)
        self.assertEqual(self.idrive("Device,Status\na,Successful\n").returncode, 0)

    def test_idrive_rejects_wrong_header_malformed_or_empty_evidence(self):
        for sample in ("Device,Status\n", "Wrong,Columns\na,Successful\n", "Device,Status\na,Successful,extra\n"):
            with self.subTest(sample=sample):
                self.assertNotEqual(self.idrive(sample).returncode, 0)

    def nintex(self, sample):
        with tempfile.TemporaryDirectory() as tmp:
            export = Path(tmp) / "export.json"
            export.write_text(sample)
            return self.run_pack("nintex-ce-platform", NINTEX_COMPONENT_ARTIFACT=str(export))

    def test_nintex_detects_encoded_tokens_without_outputting_values(self):
        for token in ("?token=noncredentialfixture", "%3Ftoken%3Dnoncredentialfixture",
                      "?other=param&amp;TOKEN=noncredentialfixture"):
            with self.subTest(token=token):
                result = self.nintex(json.dumps({"url": "https://tenant.workflowcloud.com/path"+token}))
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertTrue(json.loads(result.stdout)["needsReview"])
                self.assertNotIn("noncredentialfixture", result.stdout)

    def test_nintex_rejects_empty_and_allows_redaction(self):
        self.assertNotEqual(self.nintex("").returncode, 0)
        result = self.nintex('https://tenant.workflowcloud.com/path?token=[REDACTED]\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(json.loads(result.stdout)["needsReview"])


if __name__ == "__main__":
    unittest.main()
