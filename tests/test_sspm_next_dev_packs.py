"""Offline entry-point tests for Sumo Logic, Coralogix, Cribl Cloud and Dynatrace SaaS code packs."""

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

    def test_sumo_login_and_content_flags_are_separate(self):
        step = self.curl(
            "sumo-logic", "1.02", ["https://api.eu.sumologic.com/api/v1/serviceAllowlist/status"],
            {"loginEnabled": True, "contentEnabled": False},
            {"SUMO_DEPLOYMENT": "eu", "SUMO_ACCESS_ID": "demo", "SUMO_ACCESS_KEY": "fixture"},
            header="Authorization: Basic ZGVtbzpmaXh0dXJl",
        )
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(json.loads(step.stdout), {"loginEnabled": True, "contentEnabled": False})

    def test_sumo_fails_before_request_for_unknown_pod(self):
        step = self.curl(
            "sumo-logic", "1.02", [], {},
            {"SUMO_DEPLOYMENT": "outside.example", "SUMO_ACCESS_ID": "demo", "SUMO_ACCESS_KEY": "fixture"},
        )
        self.assertEqual(step.returncode, 2, step.stderr)
        self.assertFalse(step.stdout)

    def test_sumo_audit_false_is_valid_and_malformed_is_not(self):
        for enabled, expected in [(False, 0), ("false", 5)]:
            with self.subTest(enabled=enabled):
                step = self.curl(
                    "sumo-logic", "1.03", ["https://api.sumologic.com/api/v1/policies/audit"],
                    {"enabled": enabled},
                    {"SUMO_DEPLOYMENT": "us1", "SUMO_ACCESS_ID": "demo", "SUMO_ACCESS_KEY": "fixture"},
                    header="Authorization: Basic ZGVtbzpmaXh0dXJl",
                )
                self.assertEqual(step.returncode, expected, step.stderr)

    def test_coralogix_uses_one_explicit_profile_for_both_reads(self):
        for section, noun, verb in [("1.01", "ip-access", "get"), ("1.03", "groups", "list")]:
            with self.subTest(section=section):
                step = self.invoke(
                    "coralogix", section, "cx", ["--profile", "privacy-audit", "--output", "json", "iam", noun, verb],
                    [], {"CX_REVIEWED_PROFILE": "privacy-audit"},
                )
                self.assertEqual(step.returncode, 0, step.stderr)

    def test_cribl_inventory_binds_org_and_excludes_unused_fields(self):
        credential = {"name": "evidence", "enabled": False, "organizationId": "approved",
                      "roles": {}, "ipAllowlist": ["192.0.2.0/24"], "createdBy": "not emitted"}
        env = {"CRIBL_ORGANIZATION_ID": "approved", "CRIBL_BEARER_TOKEN": "fixture"}
        args = ["https://gateway.cribl.cloud/v1/organizations/approved/api-credentials"]
        step = self.curl("cribl-cloud", "1.01", args, {"items": [credential], "count": 1}, env)
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(set(json.loads(step.stdout)["credentials"][0]), {"name", "enabled", "roles", "ipAllowlist"})
        step = self.curl(
            "cribl-cloud", "1.01", args,
            {"items": [dict(credential, organizationId="other")], "count": 1}, env,
        )
        self.assertNotEqual(step.returncode, 0)
        self.assertFalse(step.stdout)

    def test_dynatrace_groups_are_not_effective_permissions(self):
        step = self.curl(
            "dynatrace", "1.02", [f"https://api.dynatrace.com/iam/v1/accounts/{UUID}/groups"],
            {"count": 1, "items": [{"uuid": UUID, "name": "test-viewers", "owner": "LOCAL",
                                    "federatedAttributeValues": ["not emitted"]}]},
            {"DT_ACCOUNT_UUID": UUID, "DT_ACCOUNT_BEARER_TOKEN": "fixture"},
        )
        self.assertEqual(step.returncode, 0, step.stderr)
        self.assertEqual(set(json.loads(step.stdout)["groups"][0]), {"uuid", "name", "owner"})

    def test_failed_transport_never_emits_even_a_valid_body(self):
        step = self.curl(
            "dynatrace", "1.02", [f"https://api.dynatrace.com/iam/v1/accounts/{UUID}/groups"],
            {"count": 0, "items": []}, {"DT_ACCOUNT_UUID": UUID, "DT_ACCOUNT_BEARER_TOKEN": "fixture"}, rc=28,
        )
        self.assertEqual(step.returncode, 28)
        self.assertFalse(step.stdout)


if __name__ == "__main__":
    unittest.main()
