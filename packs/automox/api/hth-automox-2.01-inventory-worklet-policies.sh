#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: automox-2.1
#   guide: https://howtoharden.com/guides/automox/
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq; AUTOMOX_API_KEY, AUTOMOX_ORG_ID
# HTH Guide Excerpt: begin inventory-worklet-policies
set +x
set -euo pipefail
umask 077
token="${AUTOMOX_API_KEY:?Set AUTOMOX_API_KEY from your approved secret store}"
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid credential format.' >&2; exit 2; }
org="${AUTOMOX_ORG_ID:?Set AUTOMOX_ORG_ID to the approved numeric organization ID}"
[[ "$org" =~ ^[1-9][0-9]{0,15}$ ]] || { printf '%s\n' 'Expected a positive numeric organization ID.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode "o=$org" 'https://console.automox.com/api/policies' |
  jq -e '
    if type != "array" or any(.[]; (.policy_type_name | type) != "string" or
      ((.id | type) != "number" and (.id | type) != "string"))
    then error("Unexpected policy response")
    else {retrievedCount: length, customPolicyIds: [ .[] | select(.policy_type_name == "custom") | .id ]}
    end'

# HTH Guide Excerpt: end inventory-worklet-policies
