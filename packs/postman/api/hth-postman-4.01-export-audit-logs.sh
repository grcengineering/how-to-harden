#!/usr/bin/env bash
# =============================================================================
# HTH Postman Control 4.1: Review Audit Logs
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2
# https://howtoharden.com/guides/postman/#41-review-audit-logs
#
# Exports team audit log events as JSON Lines for SIEM ingestion and review.
# Audit logs require a Postman Enterprise team; the key must belong to a team
# admin. Endpoint per the Postman API OpenAPI reference:
#   GET https://api.postman.com/audit/logs
#   https://learning.postman.com/api-docs/api-reference/
# Query parameters: userId, action, since (YYYY-MM-DD), until, limit, cursor,
# order_by. Each event in the "trails" array carries id, ip, userAgent,
# action, timestamp, message, and data.
# =============================================================================
set -euo pipefail

: "${POSTMAN_API_KEY:?Set POSTMAN_API_KEY to a Postman API key}"
POSTMAN_API_BASE="${POSTMAN_API_BASE:-https://api.postman.com}"
SINCE="${SINCE:-}"   # optional, YYYY-MM-DD
UNTIL="${UNTIL:-}"   # optional, YYYY-MM-DD

# HTH Guide Excerpt: begin api-export-audit-logs
# Fetch audit log events (optionally bounded by SINCE/UNTIL dates) and emit
# one JSON object per line — pipe the output into your SIEM forwarder.
QUERY=""
[ -n "${SINCE}" ] && QUERY="since=${SINCE}"
[ -n "${UNTIL}" ] && QUERY="${QUERY:+${QUERY}&}until=${UNTIL}"

AUDIT_LOGS=$(curl -sf "${POSTMAN_API_BASE}/audit/logs${QUERY:+?${QUERY}}" \
  -H "X-API-Key: ${POSTMAN_API_KEY}")

printf '%s' "${AUDIT_LOGS}" | jq -c '.trails[]'

# Summarize event volume by action so reviewers can spot anomalies
# (e.g. spikes in sign-in failures or workspace visibility changes).
printf '%s' "${AUDIT_LOGS}" | jq -r '.trails
  | group_by(.action) | map("\(length)\t\(.[0].action)") | .[]' >&2
# HTH Guide Excerpt: end api-export-audit-logs
