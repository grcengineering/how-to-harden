#!/usr/bin/env bash
# HTH Tenable Control 1.2: Implement Role-Based Access Control
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6(1)
# https://howtoharden.com/guides/tenable/#12-implement-role-based-access-control
#
# Audits Tenable Vulnerability Management user roles via the documented API.
#   List users: GET https://cloud.tenable.com/users?withRoles=true
#               https://developer.tenable.com/reference/users-list
#   Auth:       X-ApiKeys: accessKey=ACCESS_KEY;secretKey=SECRET_KEY
#   Note: the Administrator [64] role sees all attributes; lower roles see only
#   uuid, id, username, and email — run this audit with an Administrator key.
#
# Environment: TENABLE_ACCESS_KEY, TENABLE_SECRET_KEY. Requires curl and jq.
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found" >&2; exit 1; }

AUTH="X-ApiKeys: accessKey=${TENABLE_ACCESS_KEY};secretKey=${TENABLE_SECRET_KEY}"
MAX_ADMINS="${MAX_ADMINS:-3}"

# HTH Guide Excerpt: begin api-list-users-with-roles
# Pull every user with role assignments. The permissions integer encodes the
# built-in tier (64 = Administrator, 40 = Scan Manager, 16 = Basic);
# withRoles=true adds the rbac_roles array covering VM Custom Role assignments.
USERS_JSON=$(curl -sf -H "${AUTH}" \
  "https://cloud.tenable.com/users?withRoles=true")

echo "Total users: $(echo "${USERS_JSON}" | jq '.users | length')"
echo "Users by permissions tier:"
echo "${USERS_JSON}" | jq -r \
  '.users | group_by(.permissions) | .[]
    | "  permissions=\(.[0].permissions) (\(if .[0].permissions == 64 then "Administrator"
        elif .[0].permissions == 40 then "Scan Manager"
        elif .[0].permissions == 16 then "Basic"
        else "other built-in tier" end)): \(length)"'
# HTH Guide Excerpt: end api-list-users-with-roles

# HTH Guide Excerpt: begin api-flag-privileged-and-risky
# Administrators, enabled accounts that never logged in, and accounts still
# permitted to authenticate to the API are the review set: every role grant in
# Tenable is implicitly an API-key grant, since Basic and above can mint keys.
echo "Administrator [64] accounts:"
echo "${USERS_JSON}" | jq -r \
  '.users[] | select(.permissions == 64)
    | "  ADMIN: \(.username)\tenabled=\(.enabled)\tapi_permitted=\(.api_permitted)"'

echo "Enabled accounts with API access permitted:"
echo "${USERS_JSON}" | jq -r \
  '.users[] | select(.enabled == true and .api_permitted == true)
    | "  API-CAPABLE: \(.username)\tpermissions=\(.permissions)"'

echo "Enabled non-SSO accounts without SMS or email two-factor:"
echo "${USERS_JSON}" | jq -r \
  '.users[] | select(.enabled == true
      and ((.two_factor.sms_enabled // 0) != 1)
      and ((.two_factor.email_enabled // 0) != 1))
    | "  NO-MFA: \(.username)\tpermissions=\(.permissions)"'
# HTH Guide Excerpt: end api-flag-privileged-and-risky

ADMIN_COUNT=$(echo "${USERS_JSON}" | jq '[.users[] | select(.permissions == 64 and .enabled == true)] | length')
if [ "${ADMIN_COUNT}" -gt "${MAX_ADMINS}" ]; then
  echo "FAIL: ${ADMIN_COUNT} enabled Administrator accounts exceed threshold ${MAX_ADMINS}" >&2
  exit 1
fi
echo "PASS: enabled Administrator count (${ADMIN_COUNT}) within threshold (${MAX_ADMINS})"
