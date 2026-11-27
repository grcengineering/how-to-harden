#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: clickup-3.1
#   guide:   https://howtoharden.com/guides/clickup/
#   profile: L2
#   mode:    read-only
#   requires: CLICKUP_TOKEN(OAuth or personal), CLICKUP_APPROVED_WORKSPACE_IDS
# Compare token-authorized Workspace IDs with the exact review scope.
# API source: https://developer.clickup.com/reference/getauthorizedteams
# Dependencies: bash, curl (7.55+), jq
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
token=${CLICKUP_TOKEN:?Set a scoped OAuth access token or personal token}
approved=${CLICKUP_APPROVED_WORKSPACE_IDS:?Set comma-separated numeric Workspace IDs}
[[ "$approved" =~ ^[0-9]+(,[0-9]+)*$ ]] || exit 2
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2
case "$token" in
  pk_*) auth=$token ;;
  *) auth="Bearer $token" ;;
esac
body=$(printf 'Authorization: %s\n' "$auth" | curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- https://api.clickup.com/api/v2/team)
result=$(jq -ce --arg approved "$approved" '
  if (.teams|type=="array") and all(.teams[]; (.id | type=="string" or type=="number"))
  then ($approved|split(",")|unique) as $want
    | ([.teams[].id|tostring]|unique) as $got
    | {expected:$want,observed:$got,missing:($want-$got),unexpected:($got-$want),matches:($want==$got)}
  else error("invalid Workspace response") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.matches' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
