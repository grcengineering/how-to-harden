# =============================================================================
# HTH Pack Contract: v1
#   control: slack-3.1
#   guide:   https://howtoharden.com/guides/slack/#31-restrict-app-installation-and-approval
#   profile: L1
#   mode:    read-only
#   requires: SLACK_ADMIN_TOKEN(admin.apps:read user token from an org-wide Enterprise install), SLACK_TEAM_ID or SLACK_ENTERPRISE_ID(optional)
# =============================================================================
# HTH Slack Control 3.1: Audit Approved and Restricted Apps
# Profile: L1 | NIST: AC-3, CM-7
# Source: https://docs.slack.dev/reference/methods/admin.apps.approved.list
#         https://docs.slack.dev/reference/methods/admin.apps.restricted.list
#
# Both methods are Enterprise-only. Their only scope, admin.apps:read, must be
# requested by an Enterprise org admin/owner and installed on the entire
# Enterprise org, not an individual workspace. team_id and enterprise_id cannot
# be combined: team_id lists one workspace's decisions, enterprise_id the
# org-wide ones.
#
# Fails CLOSED: Slack answers auth failures with HTTP 200 and "ok": false, so
# both the status code and the ok field are checked — an audit that could not
# read the lists exits non-zero instead of printing an empty (clean-looking)
# report. Pagination follows response_metadata.next_cursor; a repeated cursor
# exits non-zero rather than looping forever.
# =============================================================================

# HTH Guide Excerpt: begin sdk-audit-approved-apps
import os
import sys

import requests

token = os.environ.get("SLACK_ADMIN_TOKEN") or sys.exit("set SLACK_ADMIN_TOKEN (admin.apps:read)")
headers = {"Authorization": f"Bearer {token}"}
scope = {}
if os.environ.get("SLACK_TEAM_ID"):
    scope["team_id"] = os.environ["SLACK_TEAM_ID"]
elif os.environ.get("SLACK_ENTERPRISE_ID"):
    scope["enterprise_id"] = os.environ["SLACK_ENTERPRISE_ID"]


def list_all(method, key):
    cursor, seen = "", set()
    while True:
        r = requests.get(
            f"https://slack.com/api/{method}",
            headers=headers,
            params={**scope, "limit": 1000, "cursor": cursor},
            timeout=30,
        )
        if r.status_code != 200:
            sys.exit(f"{method} failed: HTTP {r.status_code}")
        body = r.json()
        if not body.get("ok"):
            sys.exit(f"{method} failed: {body.get('error')}")
        yield from body.get(key, [])
        cursor = body.get("response_metadata", {}).get("next_cursor", "")
        if not cursor:
            return
        if cursor in seen:
            sys.exit(f"{method}: pagination cursor repeated, listing incomplete")
        seen.add(cursor)


for kind, method, key in (
    ("approved", "admin.apps.approved.list", "approved_apps"),
    ("restricted", "admin.apps.restricted.list", "restricted_apps"),
):
    for entry in list_all(method, key):
        app = entry["app"]
        scopes = [s["name"] for s in entry.get("scopes", [])]
        print(f"{kind}: {app['name']} ({app.get('developer_type', '?')}) scopes={scopes}")
# HTH Guide Excerpt: end sdk-audit-approved-apps
