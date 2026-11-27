#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: featureos-2.1
#   guide:   https://howtoharden.com/guides/featureos/
#   profile: L2
#   mode:    read-only
#   requires: FEATUREOS_OAUTH_TOKEN (posts:read), FEATUREOS_EXPECTED_ORG_ID, FEATUREOS_EXPECTED_ACTOR_ID, FEATUREOS_EXPECTED_ACTOR_MODE, curl, jq
# First-party source: https://developers.featureos.app/docs/oauth-apps/access-tokens
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
org=${FEATUREOS_EXPECTED_ORG_ID:?Set approved numeric organization ID}
actor_id=${FEATUREOS_EXPECTED_ACTOR_ID:?Set approved numeric actor ID}
mode=${FEATUREOS_EXPECTED_ACTOR_MODE:?Set app or self}
[[ "$org" =~ ^[1-9][0-9]*$ && "$actor_id" =~ ^[1-9][0-9]*$ && "$mode" =~ ^(app|self)$ ]] || exit 2

token=${FEATUREOS_OAUTH_TOKEN:?Set an authorized bearer credential}
[[ "$token" != *$'\r'* && "$token" != *$'\n'* ]] || exit 2

body=$(printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 40 --header @- "https://api.featureos.app/api/v3/session_info")

jq -ce --arg oid "$org" --arg uid "$actor_id" --arg actor "$mode" '
  if .success==true and (.organization.id|type)=="number"
    and (.organization.id|tostring)==$oid and (.user.id|type)=="number"
    and (.user.id|tostring)==$uid and .actor==$actor
  then {organization_id:.organization.id, actor_id:.user.id, actor_mode:.actor, matches:true}
  else error("FeatureOS OAuth binding did not match") end
' <<<"$body"
# HTH Guide Excerpt: end read-evidence
