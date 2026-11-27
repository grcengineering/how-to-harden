#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lucidchart-3.1
#   guide:   https://howtoharden.com/guides/lucidchart/
#   profile: L2
#   mode:    read-only
#   requires: LUCID_SCIM_USER_ID, LUCID_SCIM_EXPECTED_ACTIVE, LUCID_SCIM_TOKEN, curl, jq
# First-party source: https://developer.lucid.co/reference/getuser-1
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
user=${LUCID_SCIM_USER_ID:?Set the exact SCIM resource identifier}
desired=${LUCID_SCIM_EXPECTED_ACTIVE:?Set true for active or false for inactive}
[[ "$user" =~ ^[A-Za-z0-9_-]+$ && "$desired" =~ ^(true|false)$ ]] || exit 2

token=${LUCID_SCIM_TOKEN:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- --header "Accept: application/scim+json" "https://users.lucid.app/scim/v2/Users/$user")

result=$(jq -ce --arg user "$user" --argjson desired "$desired" '
  if .id==$user and (.active|type=="boolean")
  then {id, active, matches:(.active==$desired)}
  else error("Lucid SCIM ID or active flag not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.matches' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
