#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: freshdesk-1.2
#   guide: https://howtoharden.com/guides/freshdesk/#12-minimize-agent-roles-and-ticket-scope
#   profile: L1
#   mode: read-only
#   requires: curl, jq, base64, Freshdesk agent API key
# Source (reviewed 2026-11-27): https://developers.freshdesk.com/api/#list_all_agents
# HTH Guide Excerpt: begin inventory-agent-assignments
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${FRESHDESK_SUBDOMAIN:-}" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] || fail 'Missing or invalid FRESHDESK_SUBDOMAIN'
[[ "${FRESHDESK_API_KEY:-}" =~ ^[[:alnum:]_-]+$ ]] || fail 'Missing or invalid FRESHDESK_API_KEY'

page=${FRESHDESK_PAGE:-1}
[[ "$page" =~ ^[1-9][0-9]{0,3}$ ]] || fail 'Invalid page number'
auth=$(printf '%s:X' "$FRESHDESK_API_KEY" | base64 | tr -d '\r\n')
response=$(printf 'header = "Authorization: Basic %s"\n' "$auth" |
  curl --disable --config - --silent --show-error --fail --proto '=https' \
    --connect-timeout 10 --max-time 45 "https://$FRESHDESK_SUBDOMAIN.freshdesk.com/api/v2/agents?per_page=100&page=$page") || fail 'Read request did not succeed'

jq -e 'type=="array" and all(.[]; (.id|type)=="number" and (.role_ids|type)=="array" and (.group_ids|type)=="array" and (.ticket_scope|type)=="number")' <<<"$response" >/dev/null || fail 'Unexpected agent assignments response'
jq --argjson page "$page" '{scope:"one page of visible agents; verify remaining pages and role definitions separately",page:$page,agents:[.[]|{id,role_ids,group_ids,ticket_scope}]}' <<<"$response"
# HTH Guide Excerpt: end inventory-agent-assignments
