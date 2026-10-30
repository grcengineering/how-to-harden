#!/usr/bin/env python3
"""Offline regression tests for DeepWiki packs; no API, tenant, or CLI contacted."""

import copy
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PACKS = ROOT / "packs" / "deepwiki"
PROFILE = PACKS / "config/hth-deepwiki-2.02-audit-research-profile.sh"
WIKI = PACKS / "config/hth-deepwiki-3.01-validate-wiki-config.sh"
API = PACKS / "api/hth-deepwiki-1.02-indexing-inventory.sh"
PUBLIC = {"mcpServers": {"deepwiki": {"url": "https://mcp.deepwiki.com/mcp"}}}
VALID_WIKI = {"repo_notes": [], "pages": [{"title": "Architecture", "purpose": "Describe the architecture"}]}


class ConfigurationTests(unittest.TestCase):
    def run_config(self, script, value, *args):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            text = value if isinstance(value, str) else json.dumps(value)
            path.write_text(text, encoding="utf-8")
            before = path.read_bytes()
            result = subprocess.run(["bash", str(script), str(path), *args], capture_output=True, text=True)
            self.assertEqual(before, path.read_bytes(), "read-only pack changed its input")
            return result

    def test_template_is_valid_documented_json(self):
        content = (PACKS / "config/hth-deepwiki-2.01-public-mcp.jsonc").read_text()
        content = re.sub(r"^//.*\n?", "", content, flags=re.M)
        self.assertEqual(json.loads(content), PUBLIC)

    def test_public_profile_and_desktop_alias(self):
        for key in ("url", "serverUrl"):
            result = self.run_config(PROFILE, {"mcpServers": {"deepwiki": {key: "https://mcp.deepwiki.com/mcp"}}})
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("NOT PROVEN", result.stdout)

    def test_wrong_endpoint_auth_and_unrelated_servers_fail(self):
        cases = []
        for url in ("https://mcp.devin.ai/mcp", "http://mcp.deepwiki.com/mcp", "https://mcp.deepwiki.com.evil.test/mcp", "https://mcp.deepwiki.com/sse", "https://mcp.deepwiki.com/mcp?token=SECRET"):
            value = copy.deepcopy(PUBLIC)
            value["mcpServers"]["deepwiki"]["url"] = url
            cases.append(value)
        for extra in ({"headers": {"Authorization": "SECRET"}}, {"command": "SECRET"}, {"env": {"TOKEN": "SECRET"}}, {"serverUrl": "https://mcp.deepwiki.com/mcp"}):
            value = copy.deepcopy(PUBLIC)
            value["mcpServers"]["deepwiki"].update(extra)
            cases.append(value)
        value = copy.deepcopy(PUBLIC)
        value["mcpServers"]["private"] = {"url": "https://mcp.devin.ai/mcp"}
        cases.append(value)
        for value in cases:
            with self.subTest(value=value):
                result = self.run_config(PROFILE, value)
                self.assertEqual(result.returncode, 1)
                self.assertNotIn("SECRET", result.stdout + result.stderr)

    def test_malformed_and_duplicate_keys_are_unknown(self):
        for script in (PROFILE, WIKI):
            for value in ('{"SECRET":', '{"pages":[],"pages":[]}'):
                result = self.run_config(script, value)
                self.assertEqual(result.returncode, 2)
                self.assertNotIn("SECRET", result.stdout + result.stderr)

    def test_wrong_root_shapes_are_findings(self):
        for script in (PROFILE, WIKI):
            for value in ([], None, 1):
                self.assertEqual(self.run_config(script, value).returncode, 1)

    def test_valid_wiki_and_hierarchy(self):
        value = copy.deepcopy(VALID_WIKI)
        value["pages"].append({"title": "Authentication", "purpose": "Explain access checks", "parent": "Architecture", "page_notes": []})
        self.assertEqual(self.run_config(WIKI, value).returncode, 0)

    def test_nonempty_page_notes_need_manual_schema_review(self):
        for notes in ([{"content": "SECRET"}], ["SECRET"]):
            value = copy.deepcopy(VALID_WIKI)
            value["pages"][0]["page_notes"] = notes
            result = self.run_config(WIKI, value)
            self.assertEqual(result.returncode, 2)
            self.assertNotIn("SECRET", result.stdout + result.stderr)

    def test_required_pages_and_unique_titles(self):
        cases = [{"repo_notes": []}, {"repo_notes": [], "pages": []}, {"repo_notes": [], "pages": VALID_WIKI["pages"] * 2}]
        for value in cases:
            self.assertEqual(self.run_config(WIKI, value).returncode, 1)

    def test_plan_specific_page_limit(self):
        value = {"repo_notes": [], "pages": [{"title": str(i), "purpose": "Test"} for i in range(31)]}
        self.assertEqual(self.run_config(WIKI, value).returncode, 1)
        self.assertEqual(self.run_config(WIKI, value, "--enterprise").returncode, 0)
        value["pages"] = [{"title": str(i), "purpose": "Test"} for i in range(81)]
        self.assertEqual(self.run_config(WIKI, value, "--enterprise").returncode, 1)

    def test_note_count_length_and_content_redaction(self):
        value = copy.deepcopy(VALID_WIKI)
        value["repo_notes"] = [{"content": "SECRET"}] * 101
        result = self.run_config(WIKI, value)
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("SECRET", result.stdout + result.stderr)
        value["repo_notes"] = [{"content": "x" * 10001}]
        self.assertEqual(self.run_config(WIKI, value).returncode, 1)
        value["repo_notes"] = [{"content": "x" * 10000}]
        self.assertEqual(self.run_config(WIKI, value).returncode, 0)

    def test_hierarchy_cycles_and_unknown_fields(self):
        for extra in ({"parent": "Missing"}, {"parent": "Architecture"}, {"exclude": "secret.env"}, {"page_notes": "bad"}):
            value = copy.deepcopy(VALID_WIKI)
            value["pages"][0].update(extra)
            self.assertEqual(self.run_config(WIKI, value).returncode, 1)

    def test_missing_file_and_wrong_arguments_are_unknown(self):
        for script in (PROFILE, WIKI):
            result = subprocess.run(["bash", str(script), "/nonexistent/test-file.json"], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)
            result = subprocess.run(["bash", str(script)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)


CURL_STUB = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
root = pathlib.Path(os.environ["HTH_FIXTURES"])
args = sys.argv[1:]
assert args[0] == "--disable"
assert "--get" in args and "--location" not in args and "-L" not in args
assert not any("cog_" in arg for arg in args)
assert "https://api.devin.ai/v3/organizations/org-fixture/repositories/indexing" in args
assert "first=200" in args
assert args[args.index("--max-filesize") + 1] == "20971520"
auth = sys.stdin.read()
assert 'header = "Authorization: Bearer cog_fixture_only"' in auth
count_path = root / "count"
index = int(count_path.read_text()) if count_path.exists() else 0
count_path.write_text(str(index + 1))
(root / ("args-" + str(index))).write_text(json.dumps(args))
fixture = json.loads((root / (str(index) + ".json")).read_text())
status = fixture.get("status", 200)
body = fixture["body"]
output = pathlib.Path(args[args.index("--output") + 1])
output.write_text(body if isinstance(body, str) else json.dumps(body))
print(status, end="")
sys.exit(22 if status >= 400 else 0)
'''


class ApiTests(unittest.TestCase):
    def run_api(self, fixtures, key="cog_fixture_only", org="org-fixture"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "curl").write_text(CURL_STUB)
            (root / "curl").chmod(0o700)
            for index, fixture in enumerate(fixtures):
                (root / f"{index}.json").write_text(json.dumps(fixture))
            env = os.environ.copy()
            env.update(PATH=f"{root}{os.pathsep}{env['PATH']}", HTH_FIXTURES=str(root), DEVIN_API_KEY=key, DEVIN_ORG_ID=org)
            result = subprocess.run(["bash", str(API)], env=env, capture_output=True, text=True)
            calls = [json.loads(path.read_text()) for path in sorted(root.glob("args-*"))]
            self.assertNotIn(key, result.stdout + result.stderr)
            return result, calls

    def test_two_page_inventory_and_encoded_cursor(self):
        first = {"items": [{"repository_path": "test/a", "indexing_enabled": True, "branches": ["main"]}], "has_next_page": True, "end_cursor": "a+b/="}
        last = {"items": [{"repository_path": "test/b", "indexing_enabled": False, "branches": []}], "has_next_page": False, "end_cursor": None}
        result, calls = self.run_api([{"body": first}, {"body": last}])
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)
        self.assertTrue(data["complete"])
        self.assertEqual(data["repository_count"], 2)
        self.assertEqual(len(calls), 2)
        self.assertIn("after=a+b/=", calls[1])

    def test_empty_inventory_is_not_a_compliance_claim(self):
        result, _ = self.run_api([{"body": {"items": [], "has_next_page": False, "end_cursor": None}}])
        self.assertEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)["repository_count"], 0)
        self.assertIn("No compliance verdict", result.stderr)

    def test_http_errors_are_unknown_without_response_body(self):
        for status in (401, 403, 404, 429, 500):
            result, _ = self.run_api([{"status": status, "body": {"detail": "PRIVATE-DETAIL"}}])
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, "")
            self.assertNotIn("PRIVATE-DETAIL", result.stderr)

    def test_later_page_failure_never_outputs_partial_inventory(self):
        first = {"items": [{"repository_path": "private/fixture", "indexing_enabled": True, "branches": ["main"]}], "has_next_page": True, "end_cursor": "next"}
        result, calls = self.run_api([{"body": first}, {"status": 403, "body": {"detail": "PRIVATE-DETAIL"}}])
        self.assertEqual(result.returncode, 2)
        self.assertEqual(len(calls), 2)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("private/fixture", result.stderr)

    def test_unneeded_api_fields_are_not_emitted(self):
        item = {"repository_path": "test/a", "indexing_enabled": True, "branches": ["main"], "indexing_status": {"private_detail": "NOT-EMITTED"}}
        result, _ = self.run_api([{"body": {"items": [item], "extra": "NOT-EMITTED", "has_next_page": False, "end_cursor": None}}])
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("NOT-EMITTED", result.stdout + result.stderr)

    def test_malformed_shapes_and_pagination_are_unknown(self):
        for body in ("invalid", [], {"items": {}}, {"items": []}, {"items": [], "has_next_page": False}, {"items": [], "end_cursor": None}, {"items": [], "has_next_page": "false", "end_cursor": None}, {"items": [], "has_next_page": True, "end_cursor": None}, {"items": [{"repository_path": "test/a", "indexing_enabled": "true", "branches": []}], "has_next_page": False, "end_cursor": None}):
            result, _ = self.run_api([{"body": body}])
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, "")

    def test_repeated_cursor_or_repository_is_not_complete(self):
        repeated_cursor = {"items": [], "has_next_page": True, "end_cursor": "same"}
        item = {"repository_path": "test/a", "indexing_enabled": True, "branches": ["main"]}
        for fixtures in ([{"body": repeated_cursor}, {"body": repeated_cursor}], [{"body": {"items": [item, item], "has_next_page": False, "end_cursor": None}}]):
            result, _ = self.run_api(fixtures)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(result.stdout, "")

    def test_bad_credential_and_org_do_not_make_requests(self):
        for key, org in (("apk_legacy", "org-fixture"), ("cog_bad\nvalue", "org-fixture"), ("cog_fixture_only", "org-bad/path")):
            result, calls = self.run_api([], key=key, org=org)
            self.assertEqual(result.returncode, 2)
            self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
