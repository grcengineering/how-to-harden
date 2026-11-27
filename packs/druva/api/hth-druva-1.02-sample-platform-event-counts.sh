#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: druva-1.2
#   guide: https://howtoharden.com/guides/druva/#12-review-security-and-administrator-events
#   profile: L1
#   mode: read-only
#   requires: Bash, curl, jq, DRUVA_GLOBAL_ID, DRUVA_API_TOKEN
# Vendor contract: https://developer.druva.com/reference/listeventsrequest-1
# HTH Guide Excerpt: begin sample-platform-event-counts
set +x
set -euo pipefail

: "${DRUVA_GLOBAL_ID:?Set the approved commercial customer global ID}"
: "${DRUVA_API_TOKEN:?Inject the authorized Druva events bearer token}"
[[ "$DRUVA_GLOBAL_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$ ]] || exit 2
[[ "$DRUVA_API_TOKEN" =~ ^[A-Za-z0-9._~+/=-]+$ ]] || exit 2
response=$(
  printf 'Authorization: Bearer %s\n' "$DRUVA_API_TOKEN" |
    curl -q --fail --silent --show-error --proto '=https' --max-time 30 \
      --header @- --header 'Accept: application/json' \
      'https://apis.druva.com/platform/eventmanagement/v3/events?pageSize=25'
)
# A single bounded sample: do not print event data, customer IDs, or cursor tokens.
jq -e --arg id "$DRUVA_GLOBAL_ID" '
  if (.events | type) != "array" or (.events | length) > 25
    or any(.events[]; .globalID != $id or
        (.category != "EVENT" and .category != "AUDIT" and .category != "ALERT"))
  then error("unexpected event schema or customer scope")
  else {scope: "sample", returnedCount: (.events | length),
        byCategory: (.events | group_by(.category) |
          map({key: .[0].category, value: length}) | from_entries)}
  end
' <<< "$response"
# HTH Guide Excerpt: end sample-platform-event-counts
