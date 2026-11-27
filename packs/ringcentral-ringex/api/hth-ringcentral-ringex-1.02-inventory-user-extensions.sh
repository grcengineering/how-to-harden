#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ringcentral-ringex-1.2
#   guide: https://howtoharden.com/guides/ringcentral-ringex/#12-review-user-extension-lifecycle
#   profile: L1
#   mode: read-only
#   requires: curl, jq, RingEX OAuth token with ReadAccounts
# Source (reviewed 2026-11-27): https://github.com/ringcentral/ringcentral-api-docs/blob/main/docs/account/extensions.md
# HTH Guide Excerpt: begin inventory-user-extensions
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${RINGEX_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid RINGEX_ACCESS_TOKEN'
[[ "${RINGEX_ACCOUNT_ID:-}" =~ ^[0-9]{1,30}$ ]] || fail 'Missing or invalid RINGEX_ACCOUNT_ID'

page=${RINGEX_PAGE:-1}
[[ "$page" =~ ^[1-9][0-9]{0,5}$ ]] || fail 'Invalid page number'
auth=$RINGEX_ACCESS_TOKEN
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://platform.ringcentral.com/restapi/v1.0/account/$RINGEX_ACCOUNT_ID/extension?type=User&page=$page&perPage=100") || fail 'Read request did not succeed'

jq -e --argjson page "$page" '
  (.records|type=="array") and all(.records[]; (.id|type=="number" or type=="string") and
    .type=="User" and (.status|type=="string")) and
  .paging.page==$page and (.paging.totalPages|type=="number")
' <<<"$response" >/dev/null 2>&1 || fail 'Unexpected user extension collection'
jq '{page:.paging.page,total_pages:.paging.totalPages,role_grants_checked:false,extensions:[.records[]|{id,status}]}' <<<"$response"
# HTH Guide Excerpt: end inventory-user-extensions
