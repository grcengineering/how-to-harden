#!/usr/bin/env bash
# HTH GitLab Control 6.1: Enable Audit Events
# Profile: L1 | NIST: AU-2, AU-3, AU-6 | SOC 2: CC7.2
# https://howtoharden.com/guides/gitlab/#61-enable-audit-events
#
# Required: GROUP_ID environment variable (or pass as $1)
source "$(dirname "$0")/common.sh"

GROUP_ID="${GROUP_ID:-${1:-}}"
: "${GROUP_ID:?Set GROUP_ID or pass as first argument}"

banner "6.1: Enable Audit Events (Group: ${GROUP_ID})"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "6.1 Querying audit events for group ${GROUP_ID}..."

# HTH Guide Excerpt: begin api-query-audit-events
# Query group-level audit events and verify audit logging is active.
# GitLab Premium/Ultimate exposes audit events via the REST API.
info "6.1 Retrieving recent audit events..."
AUDIT_EVENTS=$(gl_get "/groups/${GROUP_ID}/audit_events?per_page=20" 2>/dev/null) || {
  fail "6.1 Failed to retrieve audit events -- requires GitLab Premium/Ultimate and admin token"
  increment_failed
  summary
  exit 0
}

EVENT_COUNT=$(echo "${AUDIT_EVENTS}" | jq 'length' 2>/dev/null || echo "0")
info "6.1 Retrieved ${EVENT_COUNT} recent audit event(s)"

if [ "${EVENT_COUNT}" -gt 0 ]; then
  # Show recent security-relevant events
  echo "${AUDIT_EVENTS}" | jq -r '.[] | "  - [\(.created_at)] \(.author.name // .author_id): \(.entity_type)/\(.details.action // .details.custom_message // "event")"' 2>/dev/null || true

  # Check for key security event types
  info "6.1 Checking for security-relevant event categories..."
  AUTH_EVENTS=$(echo "${AUDIT_EVENTS}" | jq '[.[] | select(.details.action // "" | test("auth|login|session"; "i"))] | length' 2>/dev/null || echo "0")
  PERM_EVENTS=$(echo "${AUDIT_EVENTS}" | jq '[.[] | select(.details.action // "" | test("permission|role|access"; "i"))] | length' 2>/dev/null || echo "0")
  REPO_EVENTS=$(echo "${AUDIT_EVENTS}" | jq '[.[] | select(.details.action // "" | test("push|merge|branch|tag"; "i"))] | length' 2>/dev/null || echo "0")

  info "6.1 Event breakdown: auth=${AUTH_EVENTS}, permissions=${PERM_EVENTS}, repository=${REPO_EVENTS}"
fi

# Check for audit event streaming destinations (L2)
if should_apply 2 2>/dev/null; then
  info "6.1 L2: Checking external audit event streaming destinations..."
  STREAM_DESTS=$(gl_get "/groups/${GROUP_ID}/audit_events/streaming/destinations" 2>/dev/null || echo "[]")
  DEST_COUNT=$(echo "${STREAM_DESTS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${DEST_COUNT}" -gt 0 ]; then
    pass "6.1 Found ${DEST_COUNT} audit event streaming destination(s)"
    echo "${STREAM_DESTS}" | jq -r '.[] | "  - \(.destination_url // "unknown") (verification: \(.verification_token | if . then "set" else "unset" end))"' 2>/dev/null || true
  else
    warn "6.1 No external audit event streaming destinations configured"
    warn "6.1 Configure via Settings > General > Audit events > Streaming to forward to your SIEM"
  fi
fi
# HTH Guide Excerpt: end api-query-audit-events

if [ "${EVENT_COUNT}" -gt 0 ]; then
  pass "6.1 Audit events are accessible and logging is active"
  increment_applied
else
  warn "6.1 No audit events found -- verify GitLab tier (Premium/Ultimate required) and token permissions"
  increment_failed
fi

summary
