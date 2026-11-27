#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: zoho-workdrive-1.2
#   guide: https://howtoharden.com/guides/zoho-workdrive/
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, US Zoho API access (WorkDrive.team.READ)
# HTH Guide Excerpt: begin team-membership-sample
set -euo pipefail
set +x
: "${ZOHO_WORKDRIVE_TOKEN:?Supply an approved scoped Zoho token}"
if ! [[ "${ZOHO_WORKDRIVE_TEAM_ID:?Set the WorkDrive team ID}" =~ ^[A-Za-z0-9_-]{1,128}$ ]] ||
   [[ "$ZOHO_WORKDRIVE_TOKEN" == *$'\r'* || "$ZOHO_WORKDRIVE_TOKEN" == *$'\n'* ]]; then
  printf 'Invalid identifier or credential header.\n' >&2
  exit 2
fi
token=$ZOHO_WORKDRIVE_TOKEN
unset ZOHO_WORKDRIVE_TOKEN
result=$(printf 'Authorization: Zoho-oauthtoken %s\n' "$token" |
  curl -q --silent --show-error --fail --proto '=https' --max-time 30 --header @- \
    "https://www.zohoapis.com/workdrive/api/v1/teams/$ZOHO_WORKDRIVE_TEAM_ID/users")
jq -e '
  if (.data | type) == "array" and all(.data[];
       .type == "users" and (.attributes.member_type | type) == "number")
    then .data | {returned_rows:length,
      member_type_counts:(group_by(.attributes.member_type) |
        map({member_type:.[0].attributes.member_type,count:length}))}
    else error("Unexpected WorkDrive response; no evidence reported") end
' <<< "$result"
# HTH Guide Excerpt: end team-membership-sample
