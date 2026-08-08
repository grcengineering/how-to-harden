#!/usr/bin/env bash
# HTH Clari Control 3.1: Configure Audit Logging
# Profile: L2 (Walk) | CIS Controls: 8.2 | NIST 800-53: AU-2, AU-6 | SOC 2: CC7.2
# https://howtoharden.com/guides/clari/#31-configure-audit-logging
#
# Endpoints, headers, parameters and response fields below are transcribed from
# the Clari External API specification:
#   https://developer.clari.com/documentation/external_spec
#
# Auth: per-user API token generated at Settings > API Token, sent in the
# `apikey` request header. The token carries the issuing user's access; treat it
# as a delegated credential and store it in a secret manager, never in source.
#
# Usage:
#   export CLARI_API_KEY="..."            # required
#   export CLARI_DATE_FROM="2026-07-01T00:00:00Z"   # optional (API default: 30 days ago)
#   export CLARI_DATE_TO="2026-08-01T00:00:00Z"     # optional (API default: now)
#   bash hth-clari-3.01-export-audit-events.sh

set -euo pipefail

CLARI_BASE_URL="${CLARI_BASE_URL:-https://api.clari.com/v4}"

if [[ -z "${CLARI_API_KEY:-}" ]]; then
  echo "ERROR: CLARI_API_KEY is not set. Generate a token at Settings > API Token." >&2
  exit 1
fi

for bin in curl jq; do
  command -v "${bin}" >/dev/null 2>&1 || { echo "ERROR: ${bin} is required." >&2; exit 1; }
done

clari_get() {
  # $1 = absolute URL
  curl -sS --fail-with-body -H "apikey: ${CLARI_API_KEY}" "$1"
}

# HTH Guide Excerpt: begin api-paginate-audit-events
# Page through GET /audit/events and write every event to a local NDJSON file.
# Query parameters (all optional except limit's bounds):
#   limit (1-1000, default 100) | actorId | impersonatingActorId
#   sessionId (UUID) | sessionType (WEB|IOS|ANDROID)
#   dateFrom / dateTo (ISO 8601 date-time) | event
# The 200 response carries: items[], actors[], and nextLink (pagination URL).
OUT_FILE="clari-audit-events-$(date -u +%Y%m%dT%H%M%SZ).ndjson"
: > "${OUT_FILE}"

URL="${CLARI_BASE_URL}/audit/events?limit=1000"
[[ -n "${CLARI_DATE_FROM:-}" ]] && URL="${URL}&dateFrom=${CLARI_DATE_FROM}"
[[ -n "${CLARI_DATE_TO:-}" ]]   && URL="${URL}&dateTo=${CLARI_DATE_TO}"

PAGE=0
while [[ -n "${URL}" && "${URL}" != "null" ]]; do
  PAGE=$((PAGE + 1))
  RESPONSE=$(curl -sS --fail-with-body -H "apikey: ${CLARI_API_KEY}" "${URL}")
  echo "${RESPONSE}" | jq -c '.items[]?' >> "${OUT_FILE}"
  COUNT=$(echo "${RESPONSE}" | jq '(.items // []) | length')
  echo "page ${PAGE}: ${COUNT} events"
  URL=$(echo "${RESPONSE}" | jq -r '.nextLink // empty')
done

echo "Wrote $(wc -l < "${OUT_FILE}") audit events to ${OUT_FILE}"
# HTH Guide Excerpt: end api-paginate-audit-events

# HTH Guide Excerpt: begin api-bulk-export-audit-events
# Bulk export path: queue the job, poll its status, then download the results.
#   POST  /export/audit/events        -> 202 { "jobId": "..." }
#   GET   /export/jobs/{jobId}        -> status: SCHEDULED|STARTED|DONE|FAILED|CANCELLED|ABORTED
#   GET   /export/jobs/{jobId}/results-> the export file contents
#   PATCH /export/jobs/{jobId}        -> body { "type": "CANCEL" } cancels an in-progress job
# Request body fields: actorId, impersonatingActorId, sessionId, sessionType
# (WEB|IOS|ANDROID, default WEB), dateFrom (default 30 days ago), dateTo
# (default now), event.
BODY=$(jq -n \
  --arg dateFrom "${CLARI_DATE_FROM:-}" \
  --arg dateTo   "${CLARI_DATE_TO:-}" \
  '{} + (if $dateFrom == "" then {} else {dateFrom: $dateFrom} end)
      + (if $dateTo   == "" then {} else {dateTo: $dateTo}   end)')

JOB_ID=$(curl -sS --fail-with-body -X POST \
  -H "apikey: ${CLARI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${BODY}" \
  "${CLARI_BASE_URL}/export/audit/events" | jq -r '.jobId')

echo "Queued export job ${JOB_ID}"

STATUS=""
for _ in $(seq 1 60); do
  STATUS=$(clari_get "${CLARI_BASE_URL}/export/jobs/${JOB_ID}" | jq -r '.status')
  echo "job ${JOB_ID}: ${STATUS}"
  case "${STATUS}" in
    DONE)                                  break ;;
    FAILED|CANCELLED|ABORTED) echo "Export did not complete: ${STATUS}" >&2; exit 1 ;;
  esac
  sleep 10
done

if [[ "${STATUS}" != "DONE" ]]; then
  # Free the concurrency slot rather than leaving a stuck job running.
  curl -sS --fail-with-body -X PATCH \
    -H "apikey: ${CLARI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"type":"CANCEL"}' \
    "${CLARI_BASE_URL}/export/jobs/${JOB_ID}" | jq -r '"cancel: status=\(.status) successful=\(.successful)"'
  exit 1
fi

clari_get "${CLARI_BASE_URL}/export/jobs/${JOB_ID}/results" > "clari-audit-export-${JOB_ID}"
echo "Downloaded export to clari-audit-export-${JOB_ID}"
# HTH Guide Excerpt: end api-bulk-export-audit-events

# HTH Guide Excerpt: begin api-check-export-quota
# GET /admin/limits reports the org's export job concurrency and monthly quota.
# Tracking availableMonthlyQuota against a baseline surfaces abnormal bulk-export
# activity — a spike in consumed quota means someone is pulling data in volume.
clari_get "${CLARI_BASE_URL}/admin/limits" | jq -r '
  .jobs |
  "concurrentLimit:          \(.concurrentLimit)",
  "availableConcurrentLimit: \(.availableConcurrentLimit)",
  "monthlyQuota:             \(.monthlyQuota)",
  "availableMonthlyQuota:    \(.availableMonthlyQuota)",
  "runningJobIds:            \(.runningJobIds | join(", "))",
  "submittedJobIds:          \(.submittedJobIds | join(", "))"'
# HTH Guide Excerpt: end api-check-export-quota
