#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: kanban-tool-2.1
#   guide:   https://howtoharden.com/guides/kanban-tool/
#   profile: L2
#   mode:    read-only
#   requires: KANBAN_TOOL_SUBDOMAIN, KANBAN_TOOL_EXPECTED_USER_ID, KANBAN_TOOL_TOKEN, curl, jq
# First-party source: https://kanbantool.com/developer/api-v3
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
tenant=${KANBAN_TOOL_SUBDOMAIN:?Set the exact tenant subdomain, not a full URL}
[[ "$tenant" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || exit 2

id=${KANBAN_TOOL_EXPECTED_USER_ID:?Set the approved numeric identity ID}
[[ "$id" =~ ^[1-9][0-9]*$ ]] || exit 2

token=${KANBAN_TOOL_TOKEN:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @-  "https://$tenant.kanbantool.com/api/v3/users/current.json")

jq -ce --arg expected "$id" '
  if (.id|type=="number") and (.id|tostring)==$expected
  then {id, verified_identity:true}
  else error("unexpected Kanban Tool token identity") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
