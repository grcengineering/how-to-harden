#!/usr/bin/env python3
# =============================================================================
# HTH Duo Control 2.2: Eliminate Bypass Access
# Profile: L1 | CIS Controls: 6.5 | NIST 800-53: IA-2
# https://howtoharden.com/guides/duo/#22-eliminate-bypass-access
#
# Finds every user whose status is "bypass" (skips secondary authentication
# entirely) via the official Duo Admin API Python SDK (pip install
# duo-client). Uses GET /admin/v1/users through get_users_iterator().
# Documented user status values: active, bypass, disabled, locked out,
# pending deletion. Requires an Admin API application with "Grant resource -
# Read" permission. Docs: https://duo.com/docs/adminapi
# =============================================================================
import os
import time

import duo_client

# HTH Guide Excerpt: begin sdk-audit-bypass-users
admin_api = duo_client.Admin(
    ikey=os.environ["DUO_IKEY"],
    skey=os.environ["DUO_SKEY"],
    host=os.environ["DUO_API_HOST"],
)

bypass_users = [
    user for user in admin_api.get_users_iterator()
    if user.get("status") == "bypass"
]

if not bypass_users:
    print("PASS: no users in bypass status")
else:
    print(f"WARN: {len(bypass_users)} user(s) bypass MFA entirely:")
    for user in bypass_users:
        last_login = user.get("last_login")  # Unix timestamp or None
        last_seen = (
            time.strftime("%Y-%m-%d", time.gmtime(last_login))
            if last_login else "never"
        )
        print(f"  {user.get('username')}\tlast_login={last_seen}")
    print("Bypass is for temporary troubleshooting only — set each user back")
    print("to Active or document an expiring exception (control 2.2).")
# HTH Guide Excerpt: end sdk-audit-bypass-users
