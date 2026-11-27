"""Exercise HTH pack entry points without calls to real vendor services."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
UUID = "00000000-1111-4222-a333-444444444444"
ENV = {
    "APTIBLE_APP": "demo-app", "APTIBLE_ENVIRONMENT": "sandbox",
    "CAPELLA_API_TOKEN": "opaque-fixture", "CAPELLA_ORGANIZATION_ID": UUID,
    "CAPELLA_PROJECT_ID": UUID, "CAPELLA_CLUSTER_ID": UUID,
    "REDIS_CLOUD_PLAN": "essentials", "REDIS_CLOUD_SUBSCRIPTION_ID": "21",
    "REDIS_CLOUD_DATABASE_ID": "42", "REDIS_CLOUD_ACCOUNT_KEY": "opaque-fixture",
    "REDIS_CLOUD_USER_KEY": "opaque-fixture", "ALTERYX_US1_API_TOKEN": "opaque-fixture",
}


class ThirdDevPacks(unittest.TestCase):
    def run_pack(self, vendor, section, fixture=None, url=None, **env):
        pack, = (ROOT / "packs" / vendor).glob(f"*/hth-{vendor}-1.{section:02d}-*.sh")
        with tempfile.TemporaryDirectory() as tmp:
            curl = Path(tmp) / "curl"
            curl.write_text(
                '#!/bin/bash\n'
                '[[ "$1" == -q && "${@: -1}" == "$MOCK_URL" ]] || exit 81\n'
                '[[ "$*" != *opaque-fixture* && "$*" != *--location* ]] || exit 82\n'
                'grep -q opaque-fixture || exit 83\n'
                'printf "%s" "$MOCK_FIXTURE"\n'
            )
            curl.chmod(0o755)
            aptible = Path(tmp) / "aptible"
            aptible.write_text(
                '#!/bin/bash\n'
                '[[ "$*" == "endpoints:list --environment sandbox --app demo-app" ]] || exit 80\n'
                'echo "IP Whitelist: 192.0.2.1/32"\n'
            )
            aptible.chmod(0o755)
            return subprocess.run(
                ["bash", str(pack)], capture_output=True, text=True, check=False,
                env={**ENV, "PATH": f"{tmp}:{os.environ['PATH']}", "MOCK_URL": url or "",
                     "MOCK_FIXTURE": json.dumps(fixture), **env}, timeout=5,
            )

    def test_aptible_uses_explicit_scope(self):
        result = self.run_pack("aptible", 2)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("192.0.2.1/32", result.stdout)
        self.assertEqual(self.run_pack("aptible", 2, APTIBLE_APP="--help").returncode, 2)

    def capella(self, section, fixture, **env):
        base = f"https://cloudapi.cloud.couchbase.com/v4/organizations/{UUID}/projects/{UUID}/clusters/{UUID}"
        path = "allowedcidrs?page=1&perPage=75" if section == 1 else "auditLog"
        return self.run_pack("couchbase-capella", section, fixture, f"{base}/{path}", **env)

    def test_capella_cidrs_redact_operator_identity_and_refuse_partial_results(self):
        data = [{"cidr": "192.0.2.0/24", "status": "active", "comment": "private-comment"}]
        result = self.capella(1, {"data": data, "cursor": {"pages": {"totalItems": 1}}})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(json.loads(result.stdout)["cidrs"]), 1)
        self.assertNotIn("private-comment", result.stdout)
        result = self.capella(1, {"data": data, "cursor": {"pages": {"totalItems": 2}}})
        self.assertNotEqual(result.returncode, 0)

    def test_capella_auditing_preserves_disabled_flag_and_no_names(self):
        result = self.capella(3, {"auditEnabled": False, "disabledUsers": [{"name": "masked"}],
                                  "enabledEventIDs": [[8243, 8255]]})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"auditEnabled": False, "disabledUserCount": 1,
                                                     "enabledEventIDs": [8243, 8255]})
        result = self.capella(3, {"auditEnabled": "false", "disabledUsers": [], "enabledEventIDs": []})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.capella(3, {}, CAPELLA_CLUSTER_ID="../").returncode, 2)

    def redis(self, section, fixture, plan="essentials"):
        prefix = "/fixed" if plan == "essentials" else ""
        url = f"https://api.redislabs.com/v1{prefix}/subscriptions/21/databases/42"
        return self.run_pack("redis-cloud", section, fixture, url, REDIS_CLOUD_PLAN=plan)

    def test_redis_twin_plans_tls_false_and_password_filtered(self):
        for plan in ("essentials", "pro"):
            with self.subTest(plan=plan):
                result = self.redis(1, {"databaseId": 42, "security": {"enableTls": False,
                                                                     "password": "test-db-secret"}}, plan)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse(json.loads(result.stdout)["tlsEnabled"])
                self.assertNotIn("test-db-secret", result.stdout)

    def test_redis_wrong_id_and_absent_tls_are_not_passes(self):
        self.assertNotEqual(self.redis(1, {"databaseId": 43, "security": {"enableTls": True}}).returncode, 0)
        self.assertNotEqual(self.redis(1, {"databaseId": 42, "security": {}}).returncode, 0)
        self.assertNotEqual(self.redis(1, {"databaseId": 42, "activeActiveRedis": True,
                                           "security": {"enableTls": True}}, "pro").returncode, 0)

    def test_redis_source_ranges_explicit_unknown_and_reported_empty(self):
        for value, expected in ((None, "not-reported"), ([], "reported"),
                                (["192.0.2.0/24"], "reported")):
            with self.subTest(value=value):
                result = self.redis(2, {"databaseId": 42, "security": {"sourceIps": value}})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(json.loads(result.stdout)["sourceIpEvidence"], expected)

    def test_alteryx_redacts_all_account_and_token_identifiers(self):
        url = "https://us1.alteryxcloud.com/v4/apiAccessTokens"
        meta = {"description": "private-label", "tokenId": "private-id", "createdAt": "2020-01-01",
                "person": {"email": "private-person@example.test"}}
        result = self.run_pack("alteryx-designer-cloud", 2, {"data": [meta]}, url)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["returnedCount"], 1)
        self.assertNotIn("private-", result.stdout)
        invalid = self.run_pack("alteryx-designer-cloud", 2, {"data": [None]}, url)
        self.assertNotEqual(invalid.returncode, 0)


if __name__ == "__main__":
    unittest.main()
