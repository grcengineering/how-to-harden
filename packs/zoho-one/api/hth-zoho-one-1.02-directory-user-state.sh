#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: zoho-one-1.2
#   guide: https://howtoharden.com/guides/zoho-one/
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, US Zoho API access (ZohoDirectory.Users.READ)
# HTH Guide Excerpt: begin directory-user-state
set -euo pipefail
set +x
: "${ZOHO_DIRECTORY_TOKEN:?Supply an approved scoped Zoho token}"
if ! [[ "${ZOHO_ORG_ID:?Set the organization ID}" =~ ^[0-9]{1,40}$ &&
   "${ZOHO_TEST_USER_ID:?Set the synthetic directory user ID}" =~ ^[0-9]{1,40}$ ]] ||
   [[ "$ZOHO_DIRECTORY_TOKEN" == *$'\r'* || "$ZOHO_DIRECTORY_TOKEN" == *$'\n'* ]]; then
  printf 'Invalid identifier or credential header.\n' >&2
  exit 2
fi
token=$ZOHO_DIRECTORY_TOKEN
unset ZOHO_DIRECTORY_TOKEN
result=$(printf 'Authorization: Zoho-oauthtoken %s\n' "$token" |
  curl -q --silent --show-error --fail --proto '=https' --max-time 30 --header @- \
    "https://www.zohoapis.com/directory/api/v2/orgs/$ZOHO_ORG_ID/users/$ZOHO_TEST_USER_ID")
jq -e '
  if .status_code == 200 and
      (.users.user_role | type) == "number" and (.users.user_status | type) == "number"
    then .users | {user_role,user_status}
    else error("Unexpected Zoho Directory response; no evidence reported") end
' <<< "$result"
# HTH Guide Excerpt: end directory-user-state
