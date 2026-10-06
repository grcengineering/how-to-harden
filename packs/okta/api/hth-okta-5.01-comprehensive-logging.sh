#!/usr/bin/env bash
# HTH Okta Control 5.1: Enable Comprehensive System Logging
# Profile: L1 | NIST: AU-2, AU-3, AU-6 | DISA STIG: V-273202 (HIGH)
# https://howtoharden.com/guides/okta/#51-enable-comprehensive-system-logging
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
source "$(dirname "$0")/common.sh"

banner "5.1: Enable Comprehensive System Logging"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Verifying system logging configuration..."

# HTH Guide Excerpt: begin api-check-system-log
# Verify System Log API is accessible and returning events (a failed read stops the pack)
info "5.1 Testing System Log API access..."
LOG_RESPONSE=$(okta_get "/api/v1/logs?limit=1")
LOG_COUNT=$(printf '%s' "${LOG_RESPONSE}" | jq 'length')
# HTH Guide Excerpt: end api-check-system-log

if [ "${LOG_COUNT}" -gt 0 ]; then
  LATEST_EVENT=$(printf '%s' "${LOG_RESPONSE}" | jq -r '.[0] | "\(.eventType) at \(.published)"')
  pass "5.1 System Log API accessible -- latest event: ${LATEST_EVENT}"
else
  warn "5.1 System Log API answered but returned no events"
fi

# HTH Guide Excerpt: begin api-check-log-streams
# Check for log streaming integrations
info "5.1 Checking log streaming configuration..."
LOG_STREAMS=$(okta_get "/api/v1/logStreams")
STREAM_COUNT=$(printf '%s' "${LOG_STREAMS}" | jq 'length')
ACTIVE_STREAMS=$(printf '%s' "${LOG_STREAMS}" | jq '[.[] | select(.status == "ACTIVE")] | length')
# HTH Guide Excerpt: end api-check-log-streams

if [ "${STREAM_COUNT}" -gt 0 ]; then
  info "5.1 Found ${STREAM_COUNT} log stream(s), ${ACTIVE_STREAMS} active:"
  printf '%s' "${LOG_STREAMS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status))"'
fi

if [ "${ACTIVE_STREAMS}" -gt 0 ]; then
  pass "5.1 ${ACTIVE_STREAMS} active log stream(s) forward the System Log"
else
  warn "5.1 No ACTIVE log stream -- set up SIEM forwarding via Reports > Log Streaming, or pull the System Log API"
  warn "5.1 DISA STIG V-273202 (HIGH): Centralized audit logging is required"
fi

increment_applied

summary
