#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 3.3: Delegate a Scoped Chat Moderator Role
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4/17.4 | NIST 800-53 AC-6(5), IR-4, IR-6
# Guide: https://howtoharden.com/guides/google-chat/#33-delegate-a-scoped-chat-moderator-role
#
# INTERFACE: Admin SDK Directory API — role management (ENFORCEMENT, not just audit)
#   https://developers.google.com/workspace/admin/directory/reference/rest/v1/roles/insert
#   https://developers.google.com/workspace/admin/directory/reference/rest/v1/privileges/list
#
# Requires: super administrator
#   Scope: https://www.googleapis.com/auth/admin.directory.rolemanagement
# =============================================================================
set -euo pipefail

CUSTOMER="${CUSTOMER_ID:-my_customer}"
BASE="https://admin.googleapis.com/admin/directory/v1/customer/${CUSTOMER}"

# HTH Guide Excerpt: begin api-discover-chat-privilege
# STEP 1 — discover the exact privilege, never guess it. Privilege identifiers
# and their serviceId are tenant-visible facts; print the Chat-related ones and
# copy the pair you need into step 2.
curl -s -G "${BASE}/privileges" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  | python3 -c '
import json, sys

def walk(items, depth=0):
    for p in items:
        name = p.get("privilegeName", "")
        if "CHAT" in name.upper() or "MODERAT" in name.upper():
            print(f"{name}  serviceId={p.get(\"serviceId\")}")
        walk(p.get("childPrivileges", []), depth + 1)

walk(json.load(sys.stdin).get("items", []))
'
# HTH Guide Excerpt: end api-discover-chat-privilege

# HTH Guide Excerpt: begin api-create-chat-moderator-role
# STEP 2 — create the custom role carrying ONLY the moderation privilege.
# Substitute PRIVILEGE_NAME and SERVICE_ID with the pair printed by step 1.
curl -s -X POST "${BASE}/roles" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
        "roleName": "Chat Content Moderator",
        "roleDescription": "HTH 3.3 -- triages user-reported Google Chat content in the Moderation Tool. Single privilege by design: moderation must not require super admin.",
        "rolePrivileges": [
          { "privilegeName": "PRIVILEGE_NAME", "serviceId": "SERVICE_ID" }
        ]
      }'
# HTH Guide Excerpt: end api-create-chat-moderator-role

# HTH Guide Excerpt: begin api-audit-role-assignments
# STEP 3 — ongoing: prove the role stayed narrow. A role that accumulates extra
# privileges, or assignees who left the triage rota, is the privilege-creep this
# control exists to prevent.
curl -s -G "${BASE}/roles" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  | python3 -c '
import json, sys
for r in json.load(sys.stdin).get("items", []):
    if "moderator" in r.get("roleName", "").lower():
        privs = r.get("rolePrivileges", [])
        print(f"{r[\"roleName\"]} (roleId={r[\"roleId\"]}) privileges={len(privs)}")
        for p in privs:
            print("   ", p.get("privilegeName"))
        if len(privs) > 1:
            print("    FINDING: role carries more than the single moderation privilege")
'

# Who currently holds it (pass the roleId from above).
curl -s -G "${BASE}/roleassignments" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-urlencode "roleId=ROLE_ID"
# HTH Guide Excerpt: end api-audit-role-assignments
