#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lokalise-3.1
#   guide:   https://howtoharden.com/guides/lokalise/
#   profile: L2
#   mode:    read-only
#   requires: LOKALISE_TEAM_ID, LOKALISE_USER_ID, LOKALISE_APPROVED_CLI_CONFIG, lokalise2, jq
# First-party source: https://github.com/lokalise/lokalise-cli-2-go/blob/main/docs/lokalise2_team-user_retrieve.md
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
team=${LOKALISE_TEAM_ID:?Set the exact numeric team ID}
uid=${LOKALISE_USER_ID:?Set the exact numeric user ID}
[[ "$team" =~ ^[1-9][0-9]*$ && "$uid" =~ ^[1-9][0-9]*$ ]] || exit 2

config=${LOKALISE_APPROVED_CLI_CONFIG:?Set an absolute path to an approved private CLI config}
[[ "$config" == /* && -f "$config" && ! -L "$config" ]] || exit 2
# The CLI config supplies the credential without embedding it on the command line.
body=$(lokalise2 team-user retrieve --config "$config" --team-id "$team" --user-id "$uid")

jq -ce --arg team "$team" --arg user "$uid" '
  if (.team_id|tostring)==$team and (.team_user.user_id|tostring)==$user
    and (.team_user.role|IN("owner","admin","member"))
  then {team_id,user_id:.team_user.user_id,role:.team_user.role}
  else error("Lokalise team, user, or role not verified") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
