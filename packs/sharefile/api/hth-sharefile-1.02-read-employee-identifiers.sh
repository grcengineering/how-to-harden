#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: sharefile-1.2
#   guide: https://howtoharden.com/guides/sharefile/#12-inventory-employee-privileges
#   profile: L1
#   mode: read-only
#   requires: curl, jq, approved ShareFile OAuth token
# Source (reviewed 2026-11-27): https://api.sharefile.com/docs/resource?name=Accounts ; https://api.sharefile.com/gettingstarted/odata
# HTH Guide Excerpt: begin read-employee-identifiers
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${SHAREFILE_SUBDOMAIN:-}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] || fail 'Missing or invalid SHAREFILE_SUBDOMAIN'
[[ "${SHAREFILE_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid SHAREFILE_ACCESS_TOKEN'

auth=$SHAREFILE_ACCESS_TOKEN
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$SHAREFILE_SUBDOMAIN.sf-api.com/sf/v3/Accounts/Employees") || fail 'Read request did not succeed'

jq -e '(.value|type)=="array" and all(.value[]; (.Id|type)=="string" and (.Id|length)>0) and (."odata.nextLink"==null or (."odata.nextLink"|type)=="string")' <<<"$response" >/dev/null || fail 'Unexpected employee feed response'
jq '{scope:"one .com employee page; role and client-contact details excluded",has_next_page:(."odata.nextLink"!=null),employees:[.value[]|{id:.Id}]}' <<<"$response"
# HTH Guide Excerpt: end read-employee-identifiers
