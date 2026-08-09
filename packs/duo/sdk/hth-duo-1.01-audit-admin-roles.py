#!/usr/bin/env python3
# =============================================================================
# HTH Duo Control 1.1: Secure Admin Panel Access
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6(1)
# https://howtoharden.com/guides/duo/#11-secure-admin-panel-access
#
# Audits Duo administrator accounts and their roles via the official Duo
# Admin API Python SDK (pip install duo-client). Uses GET /admin/v1/admins
# through duo_client.Admin.get_admins_iterator().
# Requires an Admin API application with "Grant administrators - Read"
# permission. Docs: https://duo.com/docs/adminapi
# SDK: https://github.com/duosecurity/duo_client_python
# =============================================================================
import os

import duo_client

# HTH Guide Excerpt: begin sdk-audit-admin-roles
admin_api = duo_client.Admin(
    ikey=os.environ["DUO_IKEY"],
    skey=os.environ["DUO_SKEY"],
    host=os.environ["DUO_API_HOST"],  # e.g. api-XXXXXXXX.duosecurity.com
)

owners = []
total = 0
for admin in admin_api.get_admins_iterator():
    total += 1
    role = admin.get("role") or ""
    print(
        f"{admin.get('name')}\t{admin.get('email')}\t"
        f"role={role}\tstatus={admin.get('status')}"
    )
    if role.lower() == "owner":
        owners.append(admin.get("email"))

print(f"\n{total} administrator(s) total; {len(owners)} hold the Owner role:")
for email in owners:
    print(f"  {email}")
if len(owners) > 2:
    print("WARN: limit Owner to 1-2 accounts — only Owners can manage other")
    print("      admins and the Admin API / Account API applications (control 1.1)")
# HTH Guide Excerpt: end sdk-audit-admin-roles
