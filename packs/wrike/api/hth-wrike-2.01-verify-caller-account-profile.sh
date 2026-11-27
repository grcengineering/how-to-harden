#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: wrike-2.1
#   guide:   https://howtoharden.com/guides/wrike/
#   profile: L2
#   mode:    read-only
#   requires: WRIKE_OAUTH_HOST(www.wrike.com only), WRIKE_TOKEN, WRIKE_EXPECTED_ACCOUNT_ID, curl, jq
# API/CLI source: https://developers.wrike.com/docs/oauth-20-authorization
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
# This pack deliberately supports the documented www.wrike.com tenant host only.
host=${WRIKE_OAUTH_HOST:?Set the host from the Wrike OAuth token response}
account=${WRIKE_EXPECTED_ACCOUNT_ID:?Set the expected Wrike account ID}
[[ "$host" == www.wrike.com && "$account" =~ ^[A-Za-z0-9]+$ ]] || exit 2
args=(--get --data-urlencode me=true)

token=${WRIKE_TOKEN:?Set a previously authorized bearer token}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
    curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "${args[@]}" "https://www.wrike.com/api/v4/contacts")

jq -ce --arg account "$account" '
  if .kind == "contacts" and (.data|type=="array" and length==1)
    and .data[0].me == true and (.data[0].id|type=="string")
    and (.data[0].profiles|type=="array")
  then [.data[0].profiles[] | select(.accountId==$account)] as $p
    | if ($p|length)==1 and ($p[0] | (.admin|type=="boolean") and (.owner|type=="boolean") and (.external|type=="boolean"))
      then {account:$account,contact:.data[0].id,admin:$p[0].admin,owner:$p[0].owner,external:$p[0].external}
      else error("expected account not verified") end
  else error("invalid self contact record") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
