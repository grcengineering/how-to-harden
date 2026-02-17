#!/usr/bin/env bash
# HTH Auth0 Control 5.1: Enable Logging and Monitoring
# Profile: L1 | NIST: AU-2, AU-6 | CIS: 8.2
# https://howtoharden.com/guides/auth0/#51-enable-logging-and-monitoring
source "$(dirname "$0")/common.sh"

banner "5.1: Enable Logging and Monitoring"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Checking log stream configuration..."

# HTH Guide Excerpt: begin api-audit-log-streams
# Audit log stream configuration
STREAMS=$(a0_get "/log-streams") || {
  fail "5.1 Unable to retrieve log streams"
  increment_failed; summary; exit 0
}

STREAM_COUNT=$(echo "${STREAMS}" | jq 'length')
ACTIVE_COUNT=$(echo "${STREAMS}" | jq '[.[] | select(.status == "active")] | length')

info "5.1 Found ${STREAM_COUNT} log stream(s), ${ACTIVE_COUNT} active"

if [ "${ACTIVE_COUNT}" -gt 0 ]; then
  pass "5.1 Active log stream(s) configured"
  echo "${STREAMS}" | jq -r '.[] | "  - \(.name) (\(.type)): \(.status)"'
else
  warn "5.1 No active log streams -- configure SIEM integration (requires Professional plan)"
fi
# HTH Guide Excerpt: end api-audit-log-streams

increment_applied
summary
