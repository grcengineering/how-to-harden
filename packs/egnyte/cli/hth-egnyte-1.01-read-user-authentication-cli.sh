#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: egnyte-1.1
#   guide: https://howtoharden.com/guides/egnyte/#11-restrict-privileged-users-and-verify-sso-assignments
#   profile: L1
#   mode: read-only
#   requires: Egnyte CLI authenticated to the approved domain, jq
# Source (reviewed 2026-11-27): https://developers.egnyte.com/integration/cfs/api-docs/agentic-cli
# HTH Guide Excerpt: begin read-user-authentication-cli
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }

start_index=${EGNYTE_START_INDEX:-1}
[[ "$start_index" =~ ^[1-9][0-9]{0,7}$ ]] || fail 'Invalid 1-based start index'

query=$(jq -cn --argjson index "$start_index" '{startIndex:$index,count:100}')
response=$(egnyte users list --json "$query" --fields startIndex,totalResults,resources.id,resources.active,resources.authType,resources.userType) || fail 'Egnyte user list did not succeed'
jq -e --argjson start "$start_index" '(.startIndex==$start and (.totalResults|type)=="number" and (.resources|type)=="array" and all(.resources[]; (.id|type)=="number" and (.active|type)=="boolean" and (.authType|type)=="string" and (.userType|type)=="string"))' <<<"$response" >/dev/null || fail 'Unexpected users response'
jq '{scope:"one Egnyte user page visible to the caller",startIndex,totalResults,users:[.resources[]|{id,active,authType,userType}]}' <<<"$response"
# HTH Guide Excerpt: end read-user-authentication-cli
