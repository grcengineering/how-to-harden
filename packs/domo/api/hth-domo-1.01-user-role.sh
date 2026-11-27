#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: domo-1.1
#   guide: https://howtoharden.com/guides/domo/#11-review-domo-security-roles
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, authorized Domo Users API OAuth access token
# Source (checked 2026-11-27): https://github.com/domoinc/domo-python-sdk/blob/master/pydomo/users/UserClient.py
# Collect narrow evidence; review locally and protect output from disclosure.

# HTH Guide Excerpt: begin domo-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_DOMO_USER_ID:?Set one reviewed Domo user ID.}"
: "${HTH_DOMO_TOKEN:?Set an authorized Domo Users API access token.}"
[[ "$HTH_DOMO_USER_ID" =~ ^[0-9]+$ ]] || fail 'Invalid Domo user ID format.'
[[ "$HTH_DOMO_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
printf 'Authorization: Bearer %s\n' "$HTH_DOMO_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    "https://api.domo.com/v1/users/$HTH_DOMO_USER_ID" |
  jq -e -s --arg id "$HTH_DOMO_USER_ID" 'if length == 1 and (.[0].id | tostring) == $id
    and (.[0].role | type) == "string" then .[0] | {id, role}
    else error("No matching Domo user/role returned") end'
# HTH Guide Excerpt: end domo-evidence
