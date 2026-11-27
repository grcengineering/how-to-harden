#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: adobe-acrobat-sign-1.4
#   guide: https://howtoharden.com/guides/adobe-acrobat-sign/#14-bind-agreement-audit-evidence-to-a-known-record
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, commercial shard and authorized agreement_read OAuth token
# Source (checked 2026-11-27): https://developer.adobe.com/acrobat-sign/docs/overview/developer_guide/apiusage
# Review locally; protect evidence from unnecessary disclosure.

# HTH Guide Excerpt: begin adobe-acrobat-sign-evidence
set +x
set -euo pipefail
fail() { printf '%s\n' "$*" >&2; exit 2; }
: "${HTH_SIGN_API_HOST:?Set the exact commercial API access point host without a scheme or path.}"
: "${HTH_SIGN_AGREEMENT_ID:?Set the approved Acrobat Sign agreement ID.}"
: "${HTH_SIGN_TOKEN:?Set an approved Acrobat Sign OAuth token.}"
[[ "$HTH_SIGN_API_HOST" =~ ^api\.[a-z][a-z0-9-]*\.(adobesign|echosign)\.com$ ]] || fail 'Invalid commercial API host.'
[[ "$HTH_SIGN_AGREEMENT_ID" =~ ^[A-Za-z0-9_-]+$ ]] || fail 'Invalid agreement ID.'
[[ "$HTH_SIGN_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || fail 'Invalid token format.'
printf 'Authorization: Bearer %s\n' "$HTH_SIGN_TOKEN" |
  curl -q --silent --show-error --fail --proto '=https' --connect-timeout 10 --max-time 30 --header @- --header 'Accept: application/json' \
    "https://$HTH_SIGN_API_HOST/api/rest/v6/agreements/$HTH_SIGN_AGREEMENT_ID" |
  jq -e -s --arg id "$HTH_SIGN_AGREEMENT_ID" 'if length == 1 and .[0].id == $id
    and (.[0].status | type) == "string" then .[0] | {id, status}
    else error("No matching agreement/status returned") end'
# HTH Guide Excerpt: end adobe-acrobat-sign-evidence
