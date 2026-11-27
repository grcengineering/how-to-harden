#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cisco-ai-defense-1.2
#   guide: https://howtoharden.com/guides/cisco-ai-defense/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; AI_DEFENSE_MANAGEMENT_KEY and AI_DEFENSE_REGION
# HTH Guide Excerpt: begin audit-runtime-connections
set +x
set -euo pipefail
umask 077

token="${AI_DEFENSE_MANAGEMENT_KEY:?Set AI_DEFENSE_MANAGEMENT_KEY from your secret manager}"
unset AI_DEFENSE_MANAGEMENT_KEY
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || { printf '%s\n' 'Invalid management key format.' >&2; exit 2; }
case "${AI_DEFENSE_REGION:?Set AI_DEFENSE_REGION to us, apj or eu}" in
  us) host=api.us.security.cisco.com ;;
  apj) host=api.apj.security.cisco.com ;;
  eu) host=api.eu.security.cisco.com ;;
  *) printf '%s\n' 'Invalid AI Defense management region.' >&2; exit 2 ;;
esac
printf 'header = "X-Cisco-AI-Defense-Tenant-API-Key: %s"\n' "$token" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45 \
    --get --data-urlencode 'limit=100' --data-urlencode 'offset=0' --data-urlencode 'expanded=false' \
    "https://$host/api/ai-defense/v1/connections" |
  jq -e '
    .connections |
    if (.items | type) != "array" or (.paging.total | type) != "number"
       or .paging.total < (.items | length)
       or any(.items[]; (type != "object") or (.connection_status | type) != "string")
    then error("Unexpected connections response")
    else {sampled: (.items | length), advertisedTotal: .paging.total,
          connected: ([.items[] | select(.connection_status == "Connected")] | length),
          disconnected: ([.items[] | select(.connection_status == "Disconnected")] | length),
          pending: ([.items[] | select(.connection_status == "Pending")] | length),
          other: ([.items[] | select(.connection_status != "Connected" and
                           .connection_status != "Disconnected" and .connection_status != "Pending")] | length)}
    end'

# HTH Guide Excerpt: end audit-runtime-connections
