"""Offline entry-point tests for Bitwarden, Fastly and Grafana Cloud code packs."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
UUID = "11111111-2222-3333-4444-555555555555"


class PackEvidenceTest(unittest.TestCase):
    """Replace network/CLI executables; never invoke a real tenant."""

    def invoke(self, vendor, section, command, args, result, env, header=None, rc=0):
        script = next((ROOT / "packs" / vendor).glob(f"*/*-{section}-*.sh"))
        with tempfile.TemporaryDirectory() as tmp:
            mock = Path(tmp, command)
            mock.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "assert sys.argv[1:] == json.loads(os.environ['MOCK_ARGS']), sys.argv[1:]\n"
                "if os.environ.get('MOCK_HEADER'):\n"
                "    assert sys.stdin.read() == os.environ['MOCK_HEADER']\n"
                "print(os.environ['MOCK_RESULT'])\n"
                "sys.exit(int(os.environ['MOCK_EXIT']))\n",
                encoding="utf-8",
            )
            mock.chmod(0o700)
            config = Path(tmp, "config.yaml")
            config.touch()
            child_env = {
                "PATH": f"{tmp}:{os.environ['PATH']}",
                "MOCK_ARGS": json.dumps([str(config) if arg == "<config>" else arg for arg in args]),
                "MOCK_RESULT": json.dumps(result),
                "MOCK_EXIT": str(rc),
                **env,
            }
            if "GRAFANA_GCX_CONFIG" in child_env:
                child_env["GRAFANA_GCX_CONFIG"] = str(config)
            if header:
                child_env["MOCK_HEADER"] = header + "\n"
            return subprocess.run(
                ["bash", str(script)], env=child_env, capture_output=True, text=True, check=False
            )

    def curl(self, vendor, section, request, fixture, env, header="Authorization: Bearer fixture", rc=0):
        args = ["-q", "--fail", "--silent", "--show-error", "--proto", "=https",
                "--max-time", "30", "--header", "@-", *request]
        return self.invoke(vendor, section, "curl", args, fixture, env, header, rc)

    def test_bitwarden_eu_policy_pagination(self):
        step = self.curl(
            "bitwarden", "1.01", ["--get", "--data-urlencode", "continuationToken=next+page=",
                                   "https://api.bitwarden.eu/public/policies"],
            {"data": [{"id": UUID, "type": 0, "enabled": True, "data": {}}], "continuationToken": "more"},
            {"BITWARDEN_ORG_BEARER_TOKEN": "fixture", "BITWARDEN_REGION": "eu",
             "BITWARDEN_CONTINUATION_TOKEN": "next+page="},
        )
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(json.loads(step.stdout), {"policies": [{"id": UUID, "type": 0, "enabled": True}],
                                                  "continuationToken": "more"})

    def test_bitwarden_invalid_region_never_reaches_curl(self):
        step = self.curl("bitwarden", "1.01", [], {}, {
            "BITWARDEN_ORG_BEARER_TOKEN": "fixture", "BITWARDEN_REGION": "bad",
        })
        self.assertEqual(step.returncode, 2, step.stderr)
        self.assertFalse(step.stdout)

    def test_bitwarden_cli_collection_metadata(self):
        step = self.invoke(
            "bitwarden", "1.02", "bw", ["list", "org-collections", "--organizationid", UUID],
            [{"id": UUID, "name": "Test Collection", "externalId": "unused"}],
            {"BITWARDEN_ORG_ID": UUID, "BW_SESSION": "fixture"},
        )
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(json.loads(step.stdout), [{"id": UUID, "name": "Test Collection"}])

    def test_fastly_distinguishes_false_from_unavailable(self):
        step = self.curl(
            "fastly", "1.01", ["https://api.fastly.com/customer/example"],
            {"id": "example", "force_2fa": False, "force_sso": True},
            {"FASTLY_CUSTOMER_ID": "example", "FASTLY_API_TOKEN": "fixture"},
            "Fastly-Key: fixture",
        )
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(json.loads(step.stdout), {
            "customer_id": "example", "force_2fa": False, "force_sso": True,
        })

    def test_fastly_rejects_wrong_customer(self):
        step = self.curl(
            "fastly", "1.01", ["https://api.fastly.com/customer/example"],
            {"id": "other", "force_2fa": True, "force_sso": True},
            {"FASTLY_CUSTOMER_ID": "example", "FASTLY_API_TOKEN": "fixture"},
            "Fastly-Key: fixture",
        )
        self.assertNotEqual(step.returncode, 0)
        self.assertFalse(step.stdout)
        self.assertIn("invalid Fastly", step.stderr)

    def test_fastly_cli_uses_requested_account(self):
        step = self.invoke(
            "fastly", "1.02", "fastly", ["user", "list", "--customer-id", "example"], [],
            {"FASTLY_CUSTOMER_ID": "example", "FASTLY_API_TOKEN": "fixture"},
        )
        self.assertEqual(step.returncode, 0, step.stderr)

    def test_grafana_mfa_must_be_boolean(self):
        step = self.curl(
            "grafana-cloud", "1.01", ["https://grafana.com/api/orgs/example/settings"],
            {"mfaRequired": "true"},
            {"GRAFANA_CLOUD_ORG_SLUG": "example", "GRAFANA_CLOUD_API_TOKEN": "fixture"},
        )
        self.assertNotEqual(step.returncode, 0)
        self.assertFalse(step.stdout)
        self.assertIn("invalid MFA", step.stderr)

    def test_transport_failure_does_not_emit_partial_evidence(self):
        step = self.curl(
            "grafana-cloud", "1.01", ["https://grafana.com/api/orgs/example/settings"],
            {"mfaRequired": True},
            {"GRAFANA_CLOUD_ORG_SLUG": "example", "GRAFANA_CLOUD_API_TOKEN": "fixture"},
            rc=28,
        )
        self.assertEqual(step.returncode, 28)
        self.assertFalse(step.stdout)

    def test_grafana_region_and_policy_are_bound(self):
        step = self.curl(
            "grafana-cloud", "1.02", ["--get", "--data-urlencode", "region=eu",
                                      f"https://www.grafana.com/api/v1/accesspolicies/{UUID}"],
            {"id": UUID, "orgId": "test", "name": "test-readers", "scopes": ["metrics:read"],
             "realms": [{"type": "stack", "identifier": "123"}],
             "conditions": {"allowedSubnets": ["192.0.2.0/24"]}},
            {"GRAFANA_CLOUD_POLICY_ID": UUID, "GRAFANA_CLOUD_REGION": "eu", "GRAFANA_CLOUD_API_TOKEN": "fixture"},
        )
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(json.loads(step.stdout)["allowedSubnets"], ["192.0.2.0/24"])

    def test_grafana_cli_limits_fields(self):
        step = self.invoke(
            "grafana-cloud", "1.04", "gcx",
            ["cloud", "orgs", "list", "--config", "<config>", "--json", "slug,role"],
            [], {"GRAFANA_GCX_CONFIG": "<config>"},
        )
        self.assertEqual(step.returncode, 0, step.stderr)


if __name__ == "__main__":
    unittest.main()
