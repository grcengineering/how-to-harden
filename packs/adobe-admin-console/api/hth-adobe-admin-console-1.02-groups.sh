#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: adobe-admin-console-1.2
#   guide: https://howtoharden.com/guides/adobe-admin-console/#12-review-roles-and-product-profiles
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, approved UMAPI client ID and OAuth access token
# Source (checked 2026-11-27): https://adobe-apiplatform.github.io/umapi-documentation/en/api/group.html
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin adobe-admin-console-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_ADOBE_ORG_ID:?Set the exact Adobe organization ID.}"
: "${HTH_ADOBE_CLIENT_ID:?Set the authorized Adobe client ID.}"
: "${HTH_ADOBE_TOKEN:?Set the approved short-lived token for this integration.}"
[[ "$HTH_ADOBE_ORG_ID" =~ ^[A-Fa-f0-9]+@AdobeOrg$ ]] || fail 'Invalid Adobe organization ID.'
[[ "$HTH_ADOBE_CLIENT_ID" =~ ^[A-Za-z0-9_-]+$ ]] || fail 'Invalid client ID.'
[[ "$HTH_ADOBE_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
printf 'Authorization: Bearer %s\nX-Api-Key: %s\n' "$HTH_ADOBE_TOKEN" "$HTH_ADOBE_CLIENT_ID" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    "https://usermanagement.adobe.io/v2/usermanagement/groups/$HTH_ADOBE_ORG_ID/0" |
  jq -e -s 'if length == 1 and .[0].result == "success" and
    (.[0].lastPage | type) == "boolean" and (.[0].groups | type) == "array"
    then .[0] | {page: 0, lastPage, groups: [.groups[] | {type, groupName, memberCount, productName}]}
    else error("No valid group/profile page returned") end'
# HTH Guide Excerpt: end adobe-admin-console-evidence
