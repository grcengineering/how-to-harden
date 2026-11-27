#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: qualtrics-xm-1.3
#   guide: https://howtoharden.com/guides/qualtrics-xm/#13-review-one-account-s-division-and-expiry
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, authorized Qualtrics token and exact user ID
# Source (checked 2026-11-27): https://developer-docs.qualtrics.com/docs/public-api/guides/common-tasks/managing-users/
# Collect narrow evidence; review locally and protect output from disclosure.

# HTH Guide Excerpt: begin qualtrics-xm-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_QUALTRICS_DATACENTER:?Set the Qualtrics datacenter ID.}"
: "${HTH_QUALTRICS_ORG_ID:?Set the Qualtrics organization ID.}"
: "${HTH_QUALTRICS_USER_ID:?Set one reviewed Qualtrics user ID.}"
: "${HTH_QUALTRICS_TOKEN:?Set an authorized Qualtrics access token.}"
[[ "$HTH_QUALTRICS_DATACENTER" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || fail 'Invalid datacenter format.'
[[ "$HTH_QUALTRICS_USER_ID" =~ ^UR_[A-Za-z0-9]+$ ]] || fail 'Invalid user ID format.'
[[ "$HTH_QUALTRICS_ORG_ID" =~ ^[A-Za-z0-9_-]+$ ]] || fail 'Invalid organization ID format.'
[[ "$HTH_QUALTRICS_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
printf 'X-API-TOKEN: %s\n' "$HTH_QUALTRICS_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    "https://$HTH_QUALTRICS_DATACENTER.qualtrics.com/API/v3/users/$HTH_QUALTRICS_USER_ID" |
  jq -e -s --arg id "$HTH_QUALTRICS_USER_ID" --arg org "$HTH_QUALTRICS_ORG_ID" '
    if length == 1 and .[0].result.id == $id and .[0].result.organizationId == $org
    then .[0].result | {id, organizationId, divisionId, accountExpirationDate}
    else error("User or organization does not match the request") end'
# HTH Guide Excerpt: end qualtrics-xm-evidence
