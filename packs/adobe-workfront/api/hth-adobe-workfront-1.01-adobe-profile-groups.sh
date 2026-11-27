#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: adobe-workfront-1.1
#   guide: https://howtoharden.com/guides/adobe-workfront/#11-review-workfront-administrator-assignments
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, authorized Adobe UMAPI client ID and OAuth token
# Source (checked 2026-11-27): https://adobe-apiplatform.github.io/umapi-documentation/en/api/getUser.html
# Collect narrow evidence; review locally and protect output from disclosure.

# HTH Guide Excerpt: begin adobe-workfront-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_ADOBE_ORG_ID:?Set the Admin Console organization ID.}"
: "${HTH_ADOBE_USER_EMAIL:?Set one reviewed user email.}"
: "${HTH_ADOBE_DIRECTORY:?Set the authoritative Adobe directory domain or AdobeID.}"
: "${HTH_ADOBE_CLIENT_ID:?Set the Adobe UMAPI client ID.}"
: "${HTH_ADOBE_TOKEN:?Set an authorized UMAPI access token.}"
[[ "$HTH_ADOBE_ORG_ID" =~ ^[A-Fa-f0-9]+@AdobeOrg$ ]] || fail 'Invalid Adobe org ID format.'
[[ "$HTH_ADOBE_USER_EMAIL" =~ ^[A-Za-z0-9._+-]+@[A-Za-z0-9.-]+$ ]] || fail 'Unsupported user email format.'
[[ "$HTH_ADOBE_DIRECTORY" =~ ^[A-Za-z0-9.-]+$ ]] || fail 'Invalid directory format.'
[[ "$HTH_ADOBE_CLIENT_ID" =~ ^[A-Za-z0-9_-]+$ ]] || fail 'Invalid client ID format.'
[[ "$HTH_ADOBE_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
printf 'Authorization: Bearer %s\nX-Api-Key: %s\n' "$HTH_ADOBE_TOKEN" "$HTH_ADOBE_CLIENT_ID" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    --get --data-urlencode "domain=$HTH_ADOBE_DIRECTORY" \
    "https://usermanagement.adobe.io/v2/usermanagement/organizations/$HTH_ADOBE_ORG_ID/users/$HTH_ADOBE_USER_EMAIL" |
  jq -e -s --arg email "$HTH_ADOBE_USER_EMAIL" 'if length == 1 and
    .[0].result == "success" and ((.[0].user.email // "") | ascii_downcase) == ($email | ascii_downcase)
    then .[0].user | {status, type, groups: (.groups // [])}
    else error("No matching user record; do not infer missing entitlement") end'
# HTH Guide Excerpt: end adobe-workfront-evidence
