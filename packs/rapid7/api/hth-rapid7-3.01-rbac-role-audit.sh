#!/usr/bin/env bash
# =============================================================================
# HTH Rapid7 Control 3.1: Implement Role-Based Access Control
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.4; NIST 800-53 AC-6
# Source: https://howtoharden.com/guides/rapid7/#31-implement-role-based-access-control
# Reference: https://docs.rapid7.com/insightvm/restful-api/
#            (full spec: https://help.rapid7.com/insightvm/en-us/api/index.html)
# InsightVM Security Console API v3. Authentication: HTTP Basic (console
# account with Global Administrator privileges). Read-only audit script.
# =============================================================================

set -euo pipefail

: "${CONSOLE_URL:?Set CONSOLE_URL (e.g. https://console.example.com:3780)}"
: "${CONSOLE_USER:?Set CONSOLE_USER}"
: "${CONSOLE_PASS:?Set CONSOLE_PASS}"

api() {
  curl -sk -u "${CONSOLE_USER}:${CONSOLE_PASS}" \
    -H "Accept: application/json" "${CONSOLE_URL}${1}"
}

# HTH Guide Excerpt: begin audit-roles-and-privileges

# --- Inventory all roles and their privilege footprint ---
# GET /api/3/roles returns every role users may be assigned
echo "=== Role inventory (name | id | privilege count) ==="
api "/api/3/roles" | jq -r '
  .resources[]
  | [.name, .id, (.privileges | length | tostring)] | join(" | ")'

# --- Flag roles that carry the all-permissions privilege ---
# Any role granting all-permissions is a Global Administrator equivalent;
# custom roles should never carry it
echo ""
echo "=== Roles granting all-permissions (Global Administrator scope) ==="
api "/api/3/roles" | jq -r '
  .resources[]
  | select(.privileges | index("all-permissions"))
  | "FLAG: role \(.name) (\(.id)) grants all-permissions"'

# --- Map users to roles to make access reviews enforceable ---
# GET /api/3/users is paged (page/size); walk every page
echo ""
echo "=== User-to-role assignments ==="
page=0
while :; do
  body=$(api "/api/3/users?page=${page}&size=500")
  echo "${body}" | jq -r '
    .resources[]
    | [.login, .role.name,
       (if .role.allSites then "all-sites" else "scoped-sites" end),
       (if .role.allAssetGroups then "all-asset-groups" else "scoped-groups" end)]
    | join(" | ")'
  total=$(echo "${body}" | jq -r '.page.totalPages')
  page=$((page + 1))
  [ "${page}" -ge "${total}" ] && break
done

# HTH Guide Excerpt: end audit-roles-and-privileges
