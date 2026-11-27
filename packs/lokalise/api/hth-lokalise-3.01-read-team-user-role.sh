#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lokalise-3.1
#   guide:   https://howtoharden.com/guides/lokalise/
#   profile: L2
#   mode:    read-only
#   requires: LOKALISE_TEAM_ID, LOKALISE_USER_ID, LOKALISE_OAUTH_TOKEN(read_team_users), curl, jq
# First-party source: https://developers.lokalise.com/reference/retrieve-a-team-user
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
team=${LOKALISE_TEAM_ID:?Set the exact numeric team ID}
uid=${LOKALISE_USER_ID:?Set the exact numeric user ID}
[[ "$team" =~ ^[1-9][0-9]*$ && "$uid" =~ ^[1-9][0-9]*$ ]] || exit 2

token=${LOKALISE_OAUTH_TOKEN:?Set a previously authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @-  "https://api.lokalise.com/api2/teams/$team/users/$uid")

jq -ce --arg team "$team" --arg user "$uid" '
  if (.team_id|tostring)==$team and (.team_user.user_id|tostring)==$user
    and (.team_user.role|IN("owner","admin","member"))
  then {team_id,user_id:.team_user.user_id,role:.team_user.role}
  else error("Lokalise team, user, or role not verified") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
