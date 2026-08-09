#!/usr/bin/env bash
# HTH OneLogin Control 5.1: Enable Audit Logging
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2
# https://howtoharden.com/guides/onelogin/#51-enable-audit-logging
#
# Interface: OneLogin REST API (first-party).
#   OAuth token: https://developers.onelogin.com/api-docs/2/oauth20-tokens/generate-tokens-2
#   Events API:  https://developers.onelogin.com/api-docs/1/events/get-events
# The v1 Events API requires the "Authorization: bearer:<token>" header format
# (note the colon) and returns up to 50 events per page with cursor pagination
# via pagination.next_link.
#
# Environment:
#   ONELOGIN_SUBDOMAIN      e.g. mycompany (for mycompany.onelogin.com)
#   ONELOGIN_CLIENT_ID      API credential pair client ID (Read All or higher)
#   ONELOGIN_CLIENT_SECRET  API credential pair client secret

set -euo pipefail
: "${ONELOGIN_SUBDOMAIN:?Set ONELOGIN_SUBDOMAIN}"
: "${ONELOGIN_CLIENT_ID:?Set ONELOGIN_CLIENT_ID}"
: "${ONELOGIN_CLIENT_SECRET:?Set ONELOGIN_CLIENT_SECRET}"
BASE_URL="https://${ONELOGIN_SUBDOMAIN}.onelogin.com"

# HTH Guide Excerpt: begin api-get-token
# Client-credentials access token (valid 10 hours).
ACCESS_TOKEN=$(curl -sf "${BASE_URL}/auth/oauth2/v2/token" \
  -X POST \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=${ONELOGIN_CLIENT_ID}" \
  --data-urlencode "client_secret=${ONELOGIN_CLIENT_SECRET}" | jq -r '.access_token')
# HTH Guide Excerpt: end api-get-token

# HTH Guide Excerpt: begin api-export-events
# Export events for a time window to newline-delimited JSON for the SIEM.
# since/until take ISO 8601 timestamps; add &event_type_id=<id> to filter to
# a single event type (see the Events API docs for the event type catalog).
SINCE="2026-08-01T00:00:00Z"
UNTIL="2026-08-08T00:00:00Z"
OUT="onelogin_events.ndjson"
: > "${OUT}"

URL="${BASE_URL}/api/1/events?since=${SINCE}&until=${UNTIL}"
while [ -n "${URL}" ] && [ "${URL}" != "null" ]; do
  PAGE=$(curl -sf "${URL}" -H "Authorization: bearer:${ACCESS_TOKEN}")
  echo "${PAGE}" | jq -c '.data[]' >> "${OUT}"
  URL=$(echo "${PAGE}" | jq -r '.pagination.next_link')
done
echo "Exported $(wc -l < "${OUT}") events to ${OUT}"
# HTH Guide Excerpt: end api-export-events

# HTH Guide Excerpt: begin api-review-recent-events
# Quick console review: most recent events with actor, target, and source IP.
curl -sf "${BASE_URL}/api/1/events?limit=50&sort=-id" \
  -H "Authorization: bearer:${ACCESS_TOKEN}" |
  jq -r '.data[] | [.created_at, .event_type_id, (.user_name // "-"),
                    (.actor_user_name // "-"), (.ipaddr // "-"), (.app_name // "-")] | @tsv'
# HTH Guide Excerpt: end api-review-recent-events
