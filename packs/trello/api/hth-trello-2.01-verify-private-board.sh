#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: trello-2.1
#   guide:   https://howtoharden.com/guides/trello/
#   profile: L1
#   mode:    read-only
#   requires: TRELLO_API_KEY, TRELLO_TOKEN(read), TRELLO_BOARD_ID, TRELLO_WORKSPACE_ID
# Verify only the specified board, separately review authorized viewers.
# API source: https://developer.atlassian.com/cloud/trello/rest/api-group-boards/
# Dependencies: bash, curl (7.55+), jq
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
key=${TRELLO_API_KEY:?Set the Trello app key}
token=${TRELLO_TOKEN:?Set a read-scoped Trello token}
board=${TRELLO_BOARD_ID:?Set the exact Trello board ID}
workspace=${TRELLO_WORKSPACE_ID:?Set the expected Trello Workspace ID}
[[ "$key" =~ ^[A-Za-z0-9_-]+$ && "$token" =~ ^[A-Za-z0-9_-]+$ ]] || exit 2
[[ "$board" =~ ^[0-9a-f]{24}$ && "$workspace" =~ ^[0-9a-f]{24}$ ]] || exit 2
body=$(printf 'Authorization: OAuth oauth_consumer_key="%s", oauth_token="%s"\n' "$key" "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- --get --data-urlencode fields=id,idOrganization,prefs "https://api.trello.com/1/boards/$board")
result=$(jq -ce --arg board "$board" --arg workspace "$workspace" '
  if .id == $board and .idOrganization == $workspace and (.prefs.permissionLevel|type=="string")
  then {board:.id,workspace:.idOrganization,visibility:.prefs.permissionLevel,private:(.prefs.permissionLevel=="private")}
  else error("board identity, Workspace, or visibility not verified") end
' <<<"$body")
printf '%s\n' "$result"
jq -e '.private' <<<"$result" >/dev/null
# HTH Guide Excerpt: end read-evidence
