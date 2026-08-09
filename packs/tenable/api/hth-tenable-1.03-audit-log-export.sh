#!/usr/bin/env bash
# HTH Tenable Control 1.3: Monitor Administrator Activity
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2
# https://howtoharden.com/guides/tenable/#13-monitor-administrator-activity
#
# Exports the Tenable Vulnerability Management audit log for SIEM ingestion and
# reviews administrator-relevant events, via the documented API.
#   Audit log: GET https://cloud.tenable.com/audit-log/v1/events
#              https://developer.tenable.com/reference/audit-log-events
#   Auth:      X-ApiKeys: accessKey=ACCESS_KEY;secretKey=SECRET_KEY
#   Filters:   f=field.operator:value (date.gt/gte/lt/lte, actor_id.eq,
#              target_id.eq, action.eq); limit max 10000; offset for paging.
#   Requires the Administrator role; Tenable retains audit data for three years.
#
# Environment: TENABLE_ACCESS_KEY, TENABLE_SECRET_KEY,
#   SINCE (YYYY-MM-DD, default 30 days back), OUT_FILE. Requires curl and jq.
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "ERROR: jq not found" >&2; exit 1; }

AUTH="X-ApiKeys: accessKey=${TENABLE_ACCESS_KEY};secretKey=${TENABLE_SECRET_KEY}"
SINCE="${SINCE:-$(date -u -d '30 days ago' +%F 2>/dev/null || date -u -v-30d +%F)}"
OUT_FILE="${OUT_FILE:-tenable-audit-log.jsonl}"
LIMIT=5000

# HTH Guide Excerpt: begin api-export-audit-log
# Page through every audit-log event since ${SINCE} and write JSON Lines for
# SIEM forwarding. Each event carries action, actor {id,name}, crud (C/R/U/D),
# received (ISO 8601), and target {id,name,type}.
: > "${OUT_FILE}"
OFFSET=0
TOTAL=0
while :; do
  PAGE=$(curl -sf -H "${AUTH}" \
    "https://cloud.tenable.com/audit-log/v1/events?f=date.gt:${SINCE}&limit=${LIMIT}&offset=${OFFSET}")
  COUNT=$(echo "${PAGE}" | jq '.events | length')
  [ "${COUNT}" -eq 0 ] && break
  echo "${PAGE}" | jq -c '.events[]' >> "${OUT_FILE}"
  TOTAL=$((TOTAL + COUNT))
  OFFSET=$((OFFSET + LIMIT))
  [ "${COUNT}" -lt "${LIMIT}" ] && break
done
echo "Exported ${TOTAL} audit events since ${SINCE} to ${OUT_FILE}"
# HTH Guide Excerpt: end api-export-audit-log

# HTH Guide Excerpt: begin api-review-admin-events
# Surface the account-and-configuration changes an attacker covering their
# tracks would generate: user creation/deletion and updates (crud C/U/D
# against user targets), grouped by actor for anomaly review.
echo "Create/update/delete events against user accounts:"
jq -r 'select(.target.type == "user" and ((.crud | ascii_downcase) as $c | $c == "c" or $c == "u" or $c == "d"))
  | "  \(.received)\t\(.action)\tactor=\(.actor.name)\ttarget=\(.target.name)"' \
  "${OUT_FILE}"

echo "Event volume by actor (top 20):"
jq -r '.actor.name // "unknown"' "${OUT_FILE}" | sort | uniq -c | sort -rn | head -20
# HTH Guide Excerpt: end api-review-admin-events
