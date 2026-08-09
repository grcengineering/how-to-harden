#!/usr/bin/env python3
# =============================================================================
# HTH Duo Control 3.1: Manage Inactive Accounts
# Profile: L1 | CIS Controls: 5.3 | NIST 800-53: AC-2
# https://howtoharden.com/guides/duo/#31-manage-inactive-accounts
#
# Reports users who have never enrolled an authenticator (is_enrolled false —
# an attacker can enroll their own device against these accounts) and users
# with no login inside the staleness window, via the official Duo Admin API
# Python SDK (pip install duo-client). Uses GET /admin/v1/users; documented
# fields: is_enrolled (bool), last_login (Unix timestamp or null), status.
# Docs: https://duo.com/docs/adminapi
# =============================================================================
import os
import time

import duo_client

STALE_DAYS = int(os.environ.get("DUO_STALE_DAYS", "90"))

# HTH Guide Excerpt: begin sdk-report-inactive-users
admin_api = duo_client.Admin(
    ikey=os.environ["DUO_IKEY"],
    skey=os.environ["DUO_SKEY"],
    host=os.environ["DUO_API_HOST"],
)

cutoff = time.time() - STALE_DAYS * 86400
never_enrolled = []
stale = []

for user in admin_api.get_users_iterator():
    if not user.get("is_enrolled"):
        never_enrolled.append(user.get("username"))
        continue
    last_login = user.get("last_login")  # Unix timestamp, or None if never
    if last_login is None or last_login < cutoff:
        stale.append((user.get("username"), last_login))

print(f"{len(never_enrolled)} user(s) provisioned but never enrolled — "
      "verify employment, then resend enrollment or delete:")
for username in never_enrolled:
    print(f"  {username}")

print(f"\n{len(stale)} enrolled user(s) with no login in {STALE_DAYS} days — "
      "disable until re-verified:")
for username, last_login in stale:
    last_seen = (
        time.strftime("%Y-%m-%d", time.gmtime(last_login))
        if last_login else "never"
    )
    print(f"  {username}\tlast_login={last_seen}")
# HTH Guide Excerpt: end sdk-report-inactive-users
