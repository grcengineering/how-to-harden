# =============================================================================
# HTH Pack Contract: v1
#   control: slack-5.1
#   guide:   https://howtoharden.com/guides/slack/#51-enable-audit-logs
#   profile: L1
#   mode:    read-only
#   requires: SLACK_AUDIT_TOKEN(auditlogs:read user token — Enterprise orgs only)
# =============================================================================
# HTH Slack Control 5.1: Audit Logs API Integration
# Profile: L1 | NIST: AU-2, AU-3, AU-6
# Source: https://docs.slack.dev/admins/audit-logs-api
#         https://docs.slack.dev/reference/audit-logs-api/methods-actions-reference
#
# Pulls the last 24 hours of user_login events. limit is optimistic (maximum
# 9999 per request) and results are cursor-paginated through
# response_metadata.next_cursor (a repeated cursor exits non-zero instead of
# looping). Fails CLOSED: a non-200 exits non-zero with the
# HTTP status (the endpoint answers an invalid token with a non-JSON 401), and a
# JSON body carrying "ok": false exits with the vendor error.
# =============================================================================

# HTH Guide Excerpt: begin sdk-audit-logs-api
import os
import sys
import time

import requests

token = os.environ.get("SLACK_AUDIT_TOKEN") or sys.exit("set SLACK_AUDIT_TOKEN (auditlogs:read)")
headers = {"Authorization": f"Bearer {token}"}
params = {"limit": 1000, "action": "user_login", "oldest": int(time.time()) - 86400}
seen = set()

while True:
    r = requests.get("https://api.slack.com/audit/v1/logs", headers=headers, params=params, timeout=30)
    if r.status_code != 200:
        sys.exit(f"audit logs request failed: HTTP {r.status_code}")
    body = r.json()
    if body.get("ok") is False:
        sys.exit(f"audit logs request failed: {body.get('error')}")
    for entry in body.get("entries", []):
        user = entry.get("actor", {}).get("user", {})
        print(f"Action: {entry['action']}, User: {user.get('email') or user.get('id')}")
    cursor = body.get("response_metadata", {}).get("next_cursor")
    if not cursor:
        break
    if cursor in seen:
        sys.exit("audit logs request failed: pagination cursor repeated, listing incomplete")
    seen.add(cursor)
    params["cursor"] = cursor
# HTH Guide Excerpt: end sdk-audit-logs-api
