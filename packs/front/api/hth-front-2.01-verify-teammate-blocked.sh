#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: front-2.1
#   guide:   https://howtoharden.com/guides/front/
#   profile: L2
#   mode:    read-only
#   requires: FRONT_OAUTH_TOKEN (teammates:read), FRONT_TEAMMATE_ID, FRONT_EXPECTED_BLOCKED, curl, jq
# First-party source: https://dev.frontapp.com/reference/get-teammate
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
id=${FRONT_TEAMMATE_ID:?Set exact Front teammate ID}
expected=${FRONT_EXPECTED_BLOCKED:?Set true or false}
[[ "$id" =~ ^tea_[a-z0-9]+$ && "$expected" =~ ^(true|false)$ ]] || exit 2

token=${FRONT_OAUTH_TOKEN:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "https://api2.frontapp.com/teammates/$id")

result=$(jq -ce --arg id "$id" --argjson expected "$expected" '
  if .id==$id and (.is_blocked|type)=="boolean"
  then {id, is_blocked, matches:(.is_blocked==$expected)}
  else error("Front teammate ID or blocked flag not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.matches' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
