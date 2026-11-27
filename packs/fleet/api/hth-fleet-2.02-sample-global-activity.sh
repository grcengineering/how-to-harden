#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: fleet-2.2
#   guide: https://howtoharden.com/guides/fleet/
#   profile: L2
#   mode: read-only
#   requires: curl, jq, Fleet API token
# HTH Fleet §2.2 Sample global activity | NIST AU-6
# Guide: https://howtoharden.com/guides/fleet/
# Source: https://fleetdm.com/docs/api/rest-api
# HTH Guide Excerpt: begin fleet-2-2
set -euo pipefail
set +x
: "${FLEET_URL:?Set the exact HTTPS Fleet server origin}"
: "${FLEET_API_TOKEN:?Supply an approved Fleet API token}"
if [[ ! "$FLEET_URL" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]+(:[0-9]{1,5})?/?$ ]] ||
   [[ "$FLEET_API_TOKEN" == *$'\r'* || "$FLEET_API_TOKEN" == *$'\n'* ]]; then
  printf 'Invalid Fleet origin or key format.\n' >&2
  exit 2
fi
token=$FLEET_API_TOKEN
unset FLEET_API_TOKEN
printf 'Authorization: Bearer %s\n' "$token" |
  curl -q --silent --show-error --fail --proto '=https' --max-time 30 --header @- \
    "${FLEET_URL%/}/api/v1/fleet/activities?page=0&per_page=50&order_key=created_at&order_direction=desc" |
  jq -e 'if (.activities | type) == "array" and
     all(.activities[]; (.type | type) == "string" and (.type | length) > 0)
  then .activities | {sample_count: length, observed_types: ([.[].type] | unique)}
  else error("Missing Fleet activities or type fields") end'
# HTH Guide Excerpt: end fleet-2-2
