#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: egnyte-1.1
#   guide: https://howtoharden.com/guides/egnyte/#11-restrict-privileged-users-and-verify-sso-assignments
#   profile: L1
#   mode: read-only
#   requires: curl, jq, approved Egnyte OAuth token
# Source (reviewed 2026-11-27): https://developers.egnyte.com/docs/read/user_management_api_documentation
# HTH Guide Excerpt: begin read-user-authentication
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${EGNYTE_SUBDOMAIN:-}" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || fail 'Missing or invalid EGNYTE_SUBDOMAIN'
[[ "${EGNYTE_ACCESS_TOKEN:-}" =~ ^[[:alnum:]_.~+/=-]+$ ]] || fail 'Missing or invalid EGNYTE_ACCESS_TOKEN'
auth=$EGNYTE_ACCESS_TOKEN

start_index=${EGNYTE_START_INDEX:-1}
[[ "$start_index" =~ ^[1-9][0-9]{0,7}$ ]] || fail 'Invalid 1-based start index'
response=$(printf 'header = "Authorization: Bearer %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$EGNYTE_SUBDOMAIN.egnyte.com/pubapi/v2/users?count=100&startIndex=$start_index") || fail 'Read request did not succeed'
jq -e --argjson start "$start_index" '(.startIndex==$start and (.totalResults|type)=="number" and (.resources|type)=="array" and all(.resources[]; (.id|type)=="number" and (.active|type)=="boolean" and (.authType|type)=="string" and (.userType|type)=="string"))' <<<"$response" >/dev/null || fail 'Unexpected users response'
jq '{scope:"one Egnyte user page visible to the caller",startIndex,totalResults,users:[.resources[]|{id,active,authType,userType}]}' <<<"$response"
# HTH Guide Excerpt: end read-user-authentication
