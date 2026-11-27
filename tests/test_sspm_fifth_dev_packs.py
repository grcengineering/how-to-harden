"""Mock the customer Anodot APIs without a live tenant or token."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ORG = "fixture-account"


class AnodotPacks(unittest.TestCase):
    def run_pack(self, section, fixture, **env):
        pack, = (ROOT / "packs" / "anodot" / "api").glob(f"*-1.{section:02d}-*.sh")
        path = "users" if section == 2 else "channels"
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
                env={"PATH": f"{tmp}:{os.environ['PATH']}", "ANODOT_HOST": "acme.anodot.com",
                     "ANODOT_BEARER_TOKEN": "opaque-fixture", "ANODOT_EXPECTED_ORG": ORG,
                     "MOCK_URL": f"https://acme.anodot.com/api/v2/{path}",
                     "MOCK_FIXTURE": json.dumps(fixture), **env},
            )

    def test_user_counts_role_and_membership_without_pii(self):
        entries = [["customer-admin"], "customer-user", ["customer-user"], ["unknown-role"]]
        fixtures = [{"roles": role, "disabled": i == 2, "groups": [],
                     "ownerOrganization": ORG, "email": "private-user@example.test"}
                    for i, role in enumerate(entries)]
        result = self.run_pack(2, fixtures)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            "users": 4, "active": 3, "activeAdmins": 1, "activeWithUnrecognizedRole": 1,
            "activeRegularUsersWithoutGroup": 1, "disabled": 1,
        })
        self.assertNotIn("private-user", result.stdout)
        self.assertNotIn("unknown-role", result.stdout)

    def test_user_empty_malformed_and_foreign_organization_rejected(self):
        for fixture in ([], {}, [{"roles": ["customer-admin"], "ownerOrganization": "foreign",
                                  "disabled": False, "groups": []}]):
            with self.subTest(fixture=fixture):
                result = self.run_pack(2, fixture)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "")

    def test_channel_counts_only_normalized_types(self):
        result = self.run_pack(3, [{"type": "SlackApp", "name": "private-channel"},
                                   {"type": "slackapp", "configuration": "private-url"}])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"visibleChannels": 2, "byType": {"slackapp": 2}})
        self.assertNotIn("private", result.stdout)
        self.assertNotEqual(self.run_pack(3, [{"type": ["webhook"]}]).returncode, 0)

    def test_reject_non_anodot_hostname_and_header_injection(self):
        for value in ("acme.anodot.com.attacker.test", "acme.anodot.com@other.test", "acme.anodot.com:443"):
            with self.subTest(host=value):
                self.assertEqual(self.run_pack(3, [], ANODOT_HOST=value).returncode, 2)
        self.assertEqual(self.run_pack(3, [], ANODOT_BEARER_TOKEN="fixture\nheader").returncode, 2)


if __name__ == "__main__":
    unittest.main()
