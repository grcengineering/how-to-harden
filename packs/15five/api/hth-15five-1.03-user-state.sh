#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: 15five-1.3
#   guide: https://howtoharden.com/guides/15five/#13-confirm-one-user-account-state-and-admin-flag
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, company-wide Public API key for approved test tenant
# Source (checked 2026-11-27): https://my.15five.com/api/public/coreapi/
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin 15five-evidence
set +x
set -euo pipefail
: "${HTH_15FIVE_SUBDOMAIN:?Set the approved company subdomain or my.}"
: "${HTH_15FIVE_USER_ID:?Set the approved user ID.}"
: "${HTH_15FIVE_KEY:?Set the company-wide Public API key.}"
[[ "$HTH_15FIVE_SUBDOMAIN" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ &&
   "$HTH_15FIVE_USER_ID" =~ ^[1-9][0-9]{0,14}$ && "$HTH_15FIVE_KEY" =~ ^[A-Za-z0-9._~+/=-]{32}$ ]] ||
  { printf 'Invalid 15Five subdomain, user ID, or key format.\n' >&2; exit 2; }
printf 'Authorization: %s\n' "$HTH_15FIVE_KEY" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @-     "https://$HTH_15FIVE_SUBDOMAIN.15five.com/api/public/user/$HTH_15FIVE_USER_ID/" |
  jq -es --arg id "$HTH_15FIVE_USER_ID" '
    if length == 1 and (.[0].id | tostring) == $id and (.[0].is_active | type) == "boolean"
      and (.[0].is_company_admin | type) == "boolean" then .[0] | {id,is_active,is_company_admin}
      else error("Unexpected 15Five user or missing state flags") end'
# HTH Guide Excerpt: end 15five-evidence
