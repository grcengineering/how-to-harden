#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: jupiterone-2.2
#   guide: https://howtoharden.com/guides/jupiterone/
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq; JUPITERONE_ACCOUNT and JUPITERONE_AUDIT_KEY
# HTH Guide Excerpt: begin audit-event-sample
set +x
set -euo pipefail
umask 077

token="${JUPITERONE_AUDIT_KEY:?Set JUPITERONE_AUDIT_KEY from your secret manager}"
account="${JUPITERONE_ACCOUNT:?Set JUPITERONE_ACCOUNT to the target account ID}"
unset JUPITERONE_AUDIT_KEY
[[ "$token" =~ ^[A-Za-z0-9._~+/=-]+$ ]] && [[ "$account" =~ ^[A-Za-z0-9_-]+$ ]] ||
  { printf '%s\n' 'Invalid key or account ID format.' >&2; exit 2; }

# GraphQL uses HTTP POST as transport. This fixed operation is a query, not a mutation.
end_ms=$(( $(date -u +%s) * 1000 ))
start_ms=$(( end_ms - 3600000 ))
# GraphQL variables are literal here and bind to the JSON variables object.
# shellcheck disable=SC2016
query='query AuditSample($limit: Int, $start: Long, $end: Long) {
  getAuditEventsForAccount(limit: $limit, startTimestamp: $start, endTimestamp: $end) {
    items { timestamp } pageInfo { hasNextPage }
  }
}'
body="$(jq -cn --arg query "$query" --argjson start "$start_ms" --argjson end "$end_ms"   '{query: $query, variables: {limit: 50, start: $start, end: $end}}')"
printf 'header = "Authorization: Bearer %s"\nheader = "JupiterOne-Account: %s"\n' "$token" "$account" |
  curl -q --config - --proto '=https' --fail --silent --show-error --connect-timeout 10 --max-time 45     --header 'Content-Type: application/json' --data-binary "$body" 'https://graphql.us.jupiterone.io/' |
  jq -e --argjson start "$start_ms" --argjson end "$end_ms" '
    if has("errors") then error("JupiterOne returned GraphQL errors") else .data.getAuditEventsForAccount end |
    if (.items | type) != "array" or (.pageInfo.hasNextPage | type) != "boolean"
      then error("Unexpected JupiterOne audit response")
      else {startMs: $start, endMs: $end, sampled: (.items | length), hasNext: .pageInfo.hasNextPage} end'
# HTH Guide Excerpt: end audit-event-sample
