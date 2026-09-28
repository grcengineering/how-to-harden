# =============================================================================
# HTH Pack Contract: v1
#   control: slack-1.2
#   guide:   https://howtoharden.com/guides/slack/#12-configure-scim-user-provisioning
#   profile: L1
#   mode:    read-only
#   requires: SLACK_ADMIN_TOKEN(admin — the only scope the SCIM API accepts; Business+ or Enterprise)
# =============================================================================
# HTH Slack Control 1.2: SCIM User Provisioning Check
# Profile: L1 | NIST: AC-2
# Source: https://docs.slack.dev/reference/scim-api
#         https://docs.slack.dev/changelog/2019-06-have-scim-will-paginate
#
# Lists every SCIM-provisioned user and whether the account is active, so the
# Slack roster can be reconciled against the IdP. Base URL is SCIM v1: the
# current docs illustrate v2 payloads, but api.slack.com answers v1 with
# missing_authentication (a recognised route) and v2 with unsupported_version.
#
# GET /Users pages at 10 by default and caps count at 1000, so this walks
# startIndex until totalResults is reached. Fails CLOSED: any non-200 exits
# non-zero with the status, and an empty first page is an error (a workspace
# always has at least the admin who minted the token), never a clean result.
# =============================================================================

# HTH Guide Excerpt: begin sdk-scim-user-listing
import os
import sys

import requests

token = os.environ.get("SLACK_ADMIN_TOKEN") or sys.exit("set SLACK_ADMIN_TOKEN (admin scope)")
headers = {"Authorization": f"Bearer {token}"}

start = 1
while True:
    r = requests.get(
        "https://api.slack.com/scim/v1/Users",
        headers=headers,
        params={"startIndex": start, "count": 1000},
        timeout=30,
    )
    if r.status_code != 200:
        sys.exit(f"SCIM request failed: HTTP {r.status_code}")
    body = r.json()
    resources = body.get("Resources", [])
    if start == 1 and not resources:
        sys.exit("SCIM returned no users: the listing is empty, not clean")
    for user in resources:
        print(f"User: {user['userName']}, Active: {user['active']}")
    start += len(resources)
    if not resources or start > body.get("totalResults", 0):
        break
# HTH Guide Excerpt: end sdk-scim-user-listing
