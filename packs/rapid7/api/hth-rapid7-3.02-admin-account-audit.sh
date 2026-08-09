#!/usr/bin/env bash
# =============================================================================
# HTH Rapid7 Control 3.2: Manage Administrator Accounts
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4; NIST 800-53 AC-6(1)
# Source: https://howtoharden.com/guides/rapid7/#32-manage-administrator-accounts
# Reference: https://docs.rapid7.com/insightvm/restful-api/
#            (full spec: https://help.rapid7.com/insightvm/en-us/api/index.html)
# InsightVM Security Console API v3. Authentication: HTTP Basic (console
# account with Global Administrator privileges). Read-only audit script:
# the 2FA check inspects only the HTTP status of GET /api/3/users/{id}/2FA
# and never prints the token seed the endpoint returns.
# =============================================================================

set -euo pipefail

: "${CONSOLE_URL:?Set CONSOLE_URL (e.g. https://console.example.com:3780)}"
: "${CONSOLE_USER:?Set CONSOLE_USER}"
: "${CONSOLE_PASS:?Set CONSOLE_PASS}"

MAX_ADMINS="${MAX_ADMINS:-3}"

api() {
  curl -sk -u "${CONSOLE_USER}:${CONSOLE_PASS}" \
    -H "Accept: application/json" "${CONSOLE_URL}${1}"
}

# HTH Guide Excerpt: begin audit-admin-accounts

# --- Inventory administrator (superuser) accounts ---
# GET /api/3/users is paged; collect every account, then filter on
# role.superuser to find Global Administrators
echo "=== Collecting user accounts ==="
users="[]"
page=0
while :; do
  body=$(api "/api/3/users?page=${page}&size=500")
  users=$(jq -s '.[0] + .[1].resources' <(echo "${users}") <(echo "${body}"))
  total=$(echo "${body}" | jq -r '.page.totalPages')
  page=$((page + 1))
  [ "${page}" -ge "${total}" ] && break
done

echo ""
echo "=== Administrator accounts (login | enabled | locked | auth source) ==="
echo "${users}" | jq -r '
  .[] | select(.role.superuser == true)
  | [.login, (.enabled | tostring), (.locked | tostring), .authentication.type]
  | join(" | ")'

# --- Enforce the admin headcount ceiling (limit Global Admins to 2-3) ---
admin_count=$(echo "${users}" | jq '[.[] | select(.role.superuser == true)] | length')
echo ""
if [ "${admin_count}" -gt "${MAX_ADMINS}" ]; then
  echo "FLAG: ${admin_count} Global Administrator accounts exceed the ${MAX_ADMINS}-admin ceiling"
else
  echo "OK: ${admin_count} Global Administrator account(s) within the ${MAX_ADMINS}-admin ceiling"
fi

# --- Flag enabled admins without console two-factor authentication ---
# GET /api/3/users/{id}/2FA returns 200 when a token seed is configured and
# 404 when it is not; only the status code is inspected here
echo ""
echo "=== Console 2FA status for enabled administrator accounts ==="
for id in $(echo "${users}" | jq -r '
    .[] | select(.role.superuser == true and .enabled == true) | .id'); do
  login=$(echo "${users}" | jq -r --argjson id "${id}" '.[] | select(.id == $id) | .login')
  status=$(curl -sk -o /dev/null -w "%{http_code}" \
    -u "${CONSOLE_USER}:${CONSOLE_PASS}" \
    -H "Accept: application/json" "${CONSOLE_URL}/api/3/users/${id}/2FA")
  if [ "${status}" = "200" ]; then
    echo "OK: ${login} has console 2FA configured"
  else
    echo "FLAG: ${login} has no console 2FA token configured (HTTP ${status})"
  fi
done

# HTH Guide Excerpt: end audit-admin-accounts
