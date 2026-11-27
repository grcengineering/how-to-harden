#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: crowdin-enterprise-3.1
#   guide:   https://howtoharden.com/guides/crowdin-enterprise/
#   profile: L2
#   mode:    read-only
#   requires: CROWDIN_ORG_SUBDOMAIN, CROWDIN_USER_ID, CROWDIN_TOKEN(user:read), curl, jq
# First-party source: https://crowdin.github.io/crowdin-api-client-js/classes/Users.html
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
organization=${CROWDIN_ORG_SUBDOMAIN:?Set the Enterprise organization subdomain}
id=${CROWDIN_USER_ID:?Set the exact numeric user ID}
[[ "$organization" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ && "$id" =~ ^[1-9][0-9]*$ ]] || exit 2

token=${CROWDIN_TOKEN:?Set a previously authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @-  "https://$organization.api.crowdin.com/api/v2/users/$id")

jq -ce --arg id "$id" '
  if (.data.id|tostring)==$id and (.data.status|IN("active","pending","blocked"))
     and (.data.twoFactor|IN("enabled","disabled"))
  then .data | {id,status,twoFactor}
  else error("Crowdin ID, status, or enrollment not verified") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
