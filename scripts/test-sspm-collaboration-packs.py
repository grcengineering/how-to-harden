#!/usr/bin/env python3
"""Offline contract checks. No tenant, credentials, or real network I/O."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
ORG = "https://api.calendly.com/organizations/TEST"
BOARD = "1" * 24
WORKSPACE = "2" * 24
FAKE = '''#!/usr/bin/env python3
import json, os, pathlib, sys
argv = sys.argv[1:]
assert '--header' in argv and '@-' in argv and '-q' in argv
assert '--fail' in argv and '--location' not in argv
assert any(a.startswith('https://') for a in argv)
assert sys.stdin.read().startswith('Authorization: ')
p = pathlib.Path(os.environ['FIXTURE'])
pages = json.loads(p.read_text())
page = pages.pop(0)
p.write_text(json.dumps(pages))
if 'query' in page:
    assert page['query'] in argv
if page.get('http_error'):
    sys.exit(22)
print(json.dumps(page['body']))
'''


class Packs(unittest.TestCase):
    def run_pack(self, vendor, suffix, env, pages, expected):
        pack, = (ROOT / "packs" / vendor / "api").glob(f"*{suffix}.sh")
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            stub = root / "curl"
            stub.write_text(FAKE)
            stub.chmod(0o755)
            fixture = root / "fixture.json"
            fixture.write_text(json.dumps(pages))
            p = subprocess.run(
                ["bash", str(pack)], text=True, capture_output=True, check=False,
                env={**os.environ, **env, "FIXTURE": str(fixture), "PATH": f"{root}:{os.environ['PATH']}"},
            )
            self.assertEqual(p.returncode, expected, p.stderr)
            if pages:
                self.assertEqual(json.loads(fixture.read_text()), [])
            return [json.loads(line) for line in p.stdout.splitlines()]

    def test_canva_minimized_and_paginated(self):
        got = self.run_pack("canva", "user-ids", {"CANVA_ADMIN_TOKEN": "mock"}, [
            {"body": {"items": [{"id": "u2", "email": "not-retained"}], "continuation": "more"}},
            {"query": "continuation=more", "body": {"items": [{"id": "u1"}]}},
        ], 0)
        self.assertEqual(got, [["u1", "u2"]])

    def test_canva_repeated_cursor_fails(self):
        self.run_pack("canva", "user-ids", {"CANVA_ADMIN_TOKEN": "mock"}, [
            {"body": {"items": [], "continuation": "more"}},
            {"query": "continuation=more", "body": {"items": [], "continuation": "more"}},
        ], 1)

    def test_calendly_roles(self):
        got = self.run_pack("calendly", "membership-roles", {
            "CALENDLY_TOKEN": "mock", "CALENDLY_ORGANIZATION_URI": ORG,
        }, [
            {"body": {"collection": [{"uri": "membership", "role": "admin", "organization": ORG}], "pagination": {"next_page_token": "more"}}},
            {"query": "page_token=more", "body": {"collection": [], "pagination": {}}},
        ], 0)
        self.assertEqual(got, [[{"uri": "membership", "role": "admin"}], []])

    def test_calendly_activity_scope(self):
        got = self.run_pack("calendly", "activity-events", {
            "CALENDLY_TOKEN": "mock", "CALENDLY_ORGANIZATION_URI": ORG,
            "CALENDLY_START_UTC": "2026-01-01T00:00:00Z", "CALENDLY_END_UTC": "2026-01-02T00:00:00Z",
        }, [{"query": f"organization={ORG}", "body": {"collection": [
            {"organization": ORG, "occurred_at": "2026-01-01T01:00:00Z", "fully_qualified_name": "Demo.Event", "details": {"private": "fixture"}},
        ], "pagination": {}}}], 0)
        self.assertEqual(got, [[{"occurred_at": "2026-01-01T01:00:00Z", "fully_qualified_name": "Demo.Event"}]])

    def test_clickup_drift(self):
        got = self.run_pack("clickup", "authorized-workspaces", {
            "CLICKUP_TOKEN": "mock", "CLICKUP_APPROVED_WORKSPACE_IDS": "123",
        }, [{"body": {"teams": [{"id": 123}, {"id": "456"}]}}], 1)
        self.assertEqual(got[0]["unexpected"], ["456"])
        self.assertFalse(got[0]["matches"])

    def test_trello_board_readback(self):
        env = {"TRELLO_TOKEN": "mock", "TRELLO_API_KEY": "mock", "TRELLO_BOARD_ID": BOARD, "TRELLO_WORKSPACE_ID": WORKSPACE}
        for visibility, status in [("private", 0), ("public", 1)]:
            with self.subTest(visibility=visibility):
                got = self.run_pack("trello", "private-board", env, [
                    {"body": {"id": BOARD, "idOrganization": WORKSPACE, "prefs": {"permissionLevel": visibility}}},
                ], status)
                self.assertEqual(got[0]["visibility"], visibility)

    def test_trello_http_error(self):
        got = self.run_pack("trello", "private-board", {
            "TRELLO_TOKEN": "mock", "TRELLO_API_KEY": "mock", "TRELLO_BOARD_ID": BOARD, "TRELLO_WORKSPACE_ID": WORKSPACE,
        }, [{"http_error": True}], 22)
        self.assertEqual(got, [])


if __name__ == "__main__":
    unittest.main()
