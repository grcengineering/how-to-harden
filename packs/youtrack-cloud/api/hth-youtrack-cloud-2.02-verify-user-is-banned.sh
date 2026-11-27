#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: youtrack-cloud-2.2
#   guide:   https://howtoharden.com/guides/youtrack-cloud/
#   profile: L2
#   mode:    read-only
#   requires: YOUTRACK_SUBDOMAIN, YOUTRACK_USER_ID, YOUTRACK_TOKEN, curl, jq
# First-party source: https://www.jetbrains.com/help/youtrack/devportal/operations-api-users.html
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
tenant=${YOUTRACK_SUBDOMAIN:?Set the exact tenant subdomain, not a full URL}
[[ "$tenant" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || exit 2

user=${YOUTRACK_USER_ID:?Set the YouTrack database ID, not a login name}
[[ "$user" =~ ^[0-9]+-[0-9]+$ ]] || exit 2

token=${YOUTRACK_TOKEN:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- --get --data-urlencode fields=id,banned "https://$tenant.youtrack.cloud/api/users/$user")

result=$(jq -ce --arg expected "$user" '
  if .id==$expected and (.banned|type=="boolean")
  then {id,banned}
  else error("YouTrack account ID or ban status not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.banned' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
