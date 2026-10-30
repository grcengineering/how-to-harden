#!/usr/bin/env python3
"""Offline contract tests for Devin GET-only packs; never contacts a tenant.

Run: python3 scripts/test-devin-api-packs.py
Only Python's standard library, bash and jq are needed. A temporary fake curl
asserts transport behavior and returns synthetic documented API response shapes.
"""
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / "packs/devin/api"
TOKEN = "cog_TEST_ONLY_NOT_A_REAL_CREDENTIAL"
FILES = {
    "roles": "hth-devin-1.03-inventory-roles-and-service-users.sh",
    "ip": "hth-devin-2.01-verify-ip-access-list.sh",
    "profiles": "hth-devin-2.02-audit-security-profile-default.sh",
    "audit": "hth-devin-4.01-collect-audit-logs.sh",
}
FAKE_CURL = '''#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
config = sys.stdin.read()
assert args[0] == '-q', 'curl must ignore user config'
assert '--location' not in args and '-L' not in args, 'must not follow redirects'
assert args[args.index('--request') + 1] == 'GET', 'read-only contract'
assert args[args.index('--proto') + 1] == '=https', 'HTTPS only'
assert os.environ['DEVIN_API_KEY'] not in ' '.join(args), 'credential leaked to argv'
assert config == 'header = "Authorization: Bearer ' + os.environ['DEVIN_API_KEY'] + '"\\n'
url = args[-1]
assert url.startswith('https://api.devin.ai/'), 'unexpected origin'
state = pathlib.Path(os.environ['HTH_TEST_STATE'])
position = int(state.read_text()) if state.exists() else 0
responses = json.loads(pathlib.Path(os.environ['HTH_TEST_RESPONSES']).read_text())
assert position < len(responses), 'unexpected additional request'
reply = responses[position]
assert url == 'https://api.devin.ai' + reply['path'], (url, reply['path'])
state.write_text(str(position + 1))
if reply.get('transport_error'):
    sys.exit(7)
body = reply.get('raw', json.dumps(reply.get('body', {})))
pathlib.Path(args[args.index('--output') + 1]).write_text(body)
print(reply.get('status', 200), end='')
'''


def page(items, cursor=None, more=False):
    return {"items": items, "end_cursor": cursor, "has_next_page": more, "total": None}


def response(path, body=None, **kw):
    return {"path": path, "body": body, **kw}


def profile(**overrides):
    base = {"profile_id": "profile_fixture", "name": "SYNTHETIC",
            "net_policy": {"allow": []}, "mcp_config": {"servers": []},
            "git_access_level": "read_only", "enforcement_level": "mandatory",
            "devin_mcp_read_only": True, "remove_github_cli_token": True,
            "created_at": 1700000000, "updated_at": 1700000001}
    base.update(overrides)
    return base


def event(identifier="fixture_event", **overrides):
    base = {"audit_log_id": identifier, "action": "ai_guardrail_violation", "created_at": 1700000010,
            "org_id": "fixture_org", "user_id": "fixture_user", "user_email": "fixture@example.invalid",
            "service_user_id": None, "service_user_name": None, "data": {"fixture": "private_data"}}
    base.update(overrides)
    return base


class DevinApiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="hth-devin-test-")
        self.directory = Path(self.temp.name)
        binary = self.directory / "curl"
        binary.write_text(FAKE_CURL)
        binary.chmod(0o700)
        self.env = dict(os.environ)
        for name in list(self.env):
            if name.startswith(("DEVIN_", "HTH_")):
                self.env.pop(name)
        self.env.update({"PATH": f"{self.directory}:{os.environ['PATH']}", "DEVIN_API_KEY": TOKEN,
                         "HTH_PROFILE_LEVEL": "2", "TMPDIR": str(self.directory),
                         "HTH_TEST_STATE": str(self.directory / "state"),
                         "HTH_TEST_RESPONSES": str(self.directory / "responses.json"),
                         "DEVIN_INVENTORY_OUTPUT": str(self.directory / "inventory.json"),
                         "DEVIN_AUDIT_OUTPUT": str(self.directory / "audit.jsonl"),
                         "DEVIN_AUDIT_AFTER": "1700000000", "DEVIN_AUDIT_BEFORE": "1700000100"})
        self.expected = self.directory / "expected.json"
        self.expected.write_text('["198.51.100.0/24", "2001:db8::/32"]')
        self.env["DEVIN_EXPECTED_IP_RANGES"] = str(self.expected)

    def tearDown(self):
        self.temp.cleanup()

    def run_pack(self, name, responses, expected=0, **env):
        (self.directory / "responses.json").write_text(json.dumps(responses))
        self.env.update(env)
        result = subprocess.run(["bash", str(PACKS / FILES[name])], env=self.env,
                                text=True, capture_output=True, timeout=15)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        self.assertNotIn(TOKEN, result.stdout + result.stderr)
        self.assertNotIn("fixture@example.invalid", result.stdout + result.stderr)
        self.assertNotIn("private_data", result.stdout + result.stderr)
        self.assertFalse(list(self.directory.glob("hth-devin.*")), "private temp evidence not cleaned")
        return result

    def profile_responses(self, value=None, selection=None):
        return [response('/v3beta1/enterprise/security-profiles?first=100', page([value or profile()])),
                response('/v3beta1/enterprise/security-profile-settings',
                         {"default": selection or {"selection": "profile", "profile_id": "profile_fixture"}})]

    def audit_response(self, items, **kw):
        return response('/v3/enterprise/audit-logs?first=100&order=asc&time_after=1700000000&time_before=1700000100', page(items), **kw)

    def test_no_token_makes_no_request(self):
        self.run_pack("ip", [], 2, DEVIN_API_KEY="")
        self.assertFalse((self.directory / "state").exists())

    def test_profile_gate_makes_no_request(self):
        self.run_pack("ip", [], 2, HTH_PROFILE_LEVEL="1")
        self.assertFalse((self.directory / "state").exists())

    def test_origin_override_refused(self):
        self.run_pack("ip", [], 2, DEVIN_API_BASE="https://example.invalid")
        self.assertFalse((self.directory / "state").exists())

    def test_header_injection_refused(self):
        self.run_pack("ip", [], 2, DEVIN_API_KEY='cog_test\nheader = "extra: nope"')
        self.assertFalse((self.directory / "state").exists())

    def test_ip_canonical_match(self):
        result = self.run_pack("ip", [response('/v3/enterprise/ip-access-list',
                               {"ip_ranges": ["2001:db8:0::/32", "198.51.100.10/24"]})])
        self.assertIn("MATCH", result.stdout)
        self.assertNotIn("198.51.100", result.stdout)

    def test_ip_drift(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {"ip_ranges": ["192.0.2.0/24"]})], 1)

    def test_ip_empty_is_unrestricted(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {"ip_ranges": []})], 1)

    def test_ip_default_route_is_unrestricted(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {"ip_ranges": ["::/0"]})], 1)

    def test_invalid_ip_is_unknown(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {"ip_ranges": ["not_a_network"]})], 2)

    def test_unsafe_approved_baseline_is_unknown(self):
        self.expected.write_text('["0.0.0.0/0"]')
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {"ip_ranges": ["192.0.2.0/24"]})], 2)

    def test_http_error_does_not_expose_body(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {"secret": "private_data"}, status=403)], 2)

    def test_redirect_fails_closed(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {}, status=302)], 2)

    def test_transport_failure_is_unknown(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', {}, transport_error=True)], 2)

    def test_invalid_json_is_unknown(self):
        self.run_pack("ip", [response('/v3/enterprise/ip-access-list', raw='<html>oops</html>')], 2)

    def test_profile_restrictive_default(self):
        self.run_pack("profiles", self.profile_responses())

    def test_profile_recommended_is_finding(self):
        self.run_pack("profiles", self.profile_responses(profile(enforcement_level="recommended")), 1)

    def test_profile_no_network_opinion_is_finding(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy=None)), 1)

    def test_profile_missing_policy_fields_unknown(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy={})), 2)

    def test_profile_null_hostname_unknown(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy={"allow": [{"hostname": None}]})), 2)

    def test_profile_invalid_cidr_unknown(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy={"allow": [{"ipv4": "invalid"}]})), 2)

    def test_profile_wrong_address_family_unknown(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy={"allow": [{"ipv4": "2001:db8::/32"}]})), 2)

    def test_profile_wildcard_network_finding(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy={"allow": [{"hostname": "*"}]})), 1)

    def test_profile_noncanonical_default_route_finding(self):
        self.run_pack("profiles", self.profile_responses(profile(net_policy={"allow": [{"ipv4": "198.51.100.1/0"}]})), 1)

    def test_profile_no_default_is_finding(self):
        self.run_pack("profiles", self.profile_responses(selection={"selection": "none"}), 1)

    def test_profile_invalid_boolean_unknown(self):
        self.run_pack("profiles", self.profile_responses(profile(devin_mcp_read_only="true")), 2)

    def test_profile_invisible_default_unknown(self):
        self.run_pack("profiles", self.profile_responses(selection={"selection": "profile", "profile_id": "missing"}), 2)

    def test_beta_unavailable_unknown(self):
        self.run_pack("profiles", [response('/v3beta1/enterprise/security-profiles?first=100', {}, status=404)], 2)

    def test_audit_collects_deduplicates_private_output(self):
        first = '/v3/enterprise/audit-logs?first=100&order=asc&time_after=1700000000&time_before=1700000100'
        self.run_pack("audit", [response(first, page([event()], "a/+", True)),
                               response(first + '&after=a%2F%2B', page([event(), event("second")]))])
        output = self.directory / "audit.jsonl"
        self.assertEqual(len(output.read_text().splitlines()), 2)
        self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)
        self.assertIn("private_data", output.read_text())

    def test_audit_action_filter(self):
        path = '/v3/enterprise/audit-logs?first=100&order=asc&time_after=1700000000&time_before=1700000100&action=ai_guardrail_violation'
        self.run_pack("audit", [response(path, page([event()]))], DEVIN_AUDIT_ACTION="ai_guardrail_violation")

    def test_audit_available_at_l1(self):
        self.run_pack("audit", [self.audit_response([])], HTH_PROFILE_LEVEL="1")

    def test_audit_empty_not_labeled_compliant(self):
        result = self.run_pack("audit", [self.audit_response([])])
        self.assertIn("0 unique", result.stdout)
        self.assertNotIn("COMPLIANT", result.stdout)

    def test_audit_existing_output_unchanged(self):
        output = self.directory / "audit.jsonl"
        output.write_text("existing evidence")
        self.run_pack("audit", [self.audit_response([event()])], 2)
        self.assertEqual(output.read_text(), "existing evidence")

    def test_audit_symlink_not_followed(self):
        target = self.directory / "target"
        target.write_text("existing evidence")
        (self.directory / "audit.jsonl").symlink_to(target)
        self.run_pack("audit", [self.audit_response([event()])], 2)
        self.assertEqual(target.read_text(), "existing evidence")

    def test_audit_repeated_cursor_discards_partial_evidence(self):
        first = '/v3/enterprise/audit-logs?first=100&order=asc&time_after=1700000000&time_before=1700000100'
        self.run_pack("audit", [response(first, page([event()], "repeat", True)),
                               response(first + '&after=repeat', page([event()], "repeat", True))], 2)
        self.assertFalse((self.directory / "audit.jsonl").exists())

    def test_audit_missing_cursor_discards_partial_evidence(self):
        first = '/v3/enterprise/audit-logs?first=100&order=asc&time_after=1700000000&time_before=1700000100'
        self.run_pack("audit", [response(first, page([event()], None, True))], 2)
        self.assertFalse((self.directory / "audit.jsonl").exists())

    def test_audit_page_limit_is_unknown(self):
        first = '/v3/enterprise/audit-logs?first=100&order=asc&time_after=1700000000&time_before=1700000100'
        self.run_pack("audit", [response(first, page([event()], "next", True))], 2, HTH_MAX_PAGES="1")
        self.assertFalse((self.directory / "audit.jsonl").exists())

    def test_audit_bad_window_makes_no_request(self):
        self.run_pack("audit", [], 2, DEVIN_AUDIT_BEFORE="1709999999")
        self.assertFalse((self.directory / "state").exists())

    def test_audit_event_outside_window_no_output(self):
        self.run_pack("audit", [self.audit_response([event(created_at=1699999999)])], 2)
        self.assertFalse((self.directory / "audit.jsonl").exists())

    def test_audit_bad_event_no_output(self):
        self.run_pack("audit", [self.audit_response([{"action": "unknown"}])], 2)
        self.assertFalse((self.directory / "audit.jsonl").exists())

    def test_roles_inventory_fetches_permissions_private_output(self):
        role = {"role_id": "fixture_role", "role_name": "Fixture Role", "role_type": "enterprise"}
        user = {"service_user_id": "fixture_service", "name": "Fixture Service", "expires_at": None,
                "deleted_at": None, "role_assignments": [{"role": role, "org_id": None}]}
        self.run_pack("roles", [response('/v3/self', {"principal_type": "service_user", "service_user_id": "fixture_service"}),
                                response('/v3/enterprise/roles?first=100', page([role])),
                                response('/v3/enterprise/members/service-users?first=100&include_inactive=true', page([user])),
                                response('/v3/enterprise/roles/fixture_role', {**role, "permissions": ["ViewAccountAuditLogs"]})])
        output = self.directory / "inventory.json"
        self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o600)
        self.assertEqual(json.loads(output.read_text())["roles"][0]["permissions"], ["ViewAccountAuditLogs"])

    def test_roles_refuses_personal_token(self):
        self.run_pack("roles", [response('/v3/self', {"principal_type": "pat_user"})], 2)
        self.assertFalse((self.directory / "inventory.json").exists())

    def test_roles_missing_permission_array_unknown(self):
        role = {"role_id": "fixture_role", "role_name": "Fixture Role", "role_type": "enterprise"}
        self.run_pack("roles", [response('/v3/self', {"principal_type": "service_user", "service_user_id": "fixture_service"}),
                                response('/v3/enterprise/roles?first=100', page([role])),
                                response('/v3/enterprise/members/service-users?first=100&include_inactive=true', page([])),
                                response('/v3/enterprise/roles/fixture_role', role)], 2)
        self.assertFalse((self.directory / "inventory.json").exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
