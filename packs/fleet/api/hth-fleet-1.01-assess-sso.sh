#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: fleet-1.1
#   guide: https://howtoharden.com/guides/fleet/
#   profile: L1
#   mode: read-only
#   requires: curl, jq, Fleet API token
# HTH Fleet §1.1 Assess administrator SSO | NIST IA-2
# Guide: https://howtoharden.com/guides/fleet/
# Source: https://fleetdm.com/docs/api/rest-api
# HTH Guide Excerpt: begin fleet-1-1
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
    "${FLEET_URL%/}/api/v1/fleet/sso" |
  jq -e 'if (.settings.sso_enabled | type) == "boolean" then
    .settings | {sso_enabled}
  else error("Missing Fleet SSO state") end'
# HTH Guide Excerpt: end fleet-1-1
