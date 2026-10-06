#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 8.2: Enable Audit Logging with SIEM Streaming
# Profile Level: L2 (Walk)
# Frameworks: NIST AU-2, AU-3, AU-12
# Source: https://howtoharden.com/guides/vercel/#82-enable-audit-logging-with-siem-streaming
# API: GET /v3/events (listUserEvents; event type names per
#      https://vercel.com/docs/activity-log#events-logged), GET /v1/drains
#      (getDrains). Read-only. Audit logs now ride Drains; the Terraform surface
#      is vercel_audit_log_drain.
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"

# HTH Guide Excerpt: begin api

# curl -f: an HTTP 4xx/5xx aborts instead of reporting an empty event list.
vercel_get() {
  curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" "https://api.vercel.com$1"
}

# Security-critical event types to alert on (names as documented in the
# Activity Log event table).
CRITICAL_TYPES="team-member-role-update,team-member-add,team-member-delete"
CRITICAL_TYPES+=",env-variable-add,env-variable-edit,env-variable-read"
CRITICAL_TYPES+=",project-sso-protection,project-password-protection,password-protection-disabled"
CRITICAL_TYPES+=",saml-connection-created,saml-connection-deleted"
CRITICAL_TYPES+=",integration-installation-completed,domain,user-token-created"

# --- Recent security-critical events, counted by type ---
echo "=== Security-Critical Events (last 100) ==="
EVENTS_JSON="$(vercel_get "/v3/events?teamId=${VERCEL_TEAM_ID}&limit=100&types=${CRITICAL_TYPES}")"
echo "${EVENTS_JSON}" | jq '[.events[] | .type] | group_by(.) | map({type: .[0], count: length})'

echo ""
echo "=== Most Recent 10 ==="
echo "${EVENTS_JSON}" | jq '[.events[]][:10][] | {id, type, createdAt, principalId, text}'

# --- Drains carrying audit/log data (endpoint host only: a drain's full
#     delivery object can carry its signature secret and auth headers) ---
echo ""
echo "=== Drain Status ==="
vercel_get "/v1/drains?teamId=${VERCEL_TEAM_ID}" | jq '.drains[] | {
  id, name, status, source,
  schemas: (.schemas // {} | keys),
  deliveryType: .delivery.type,
  endpointHost: (.delivery.endpoint | if type == "string" then (capture("^(?<h>[a-z]+://[^/?#]+)").h // "unparsed") else "non-http" end)
}'

# HTH Guide Excerpt: end api
