#!/usr/bin/env bash
# HTH Okta Control 5.1: Enable Comprehensive System Logging
# Profile: L1 | NIST: AU-2, AU-3, AU-6 | DISA STIG: V-273202 (HIGH)
# https://howtoharden.com/guides/okta/#51-enable-comprehensive-system-logging
source "$(dirname "$0")/common.sh"

banner "5.1: Enable Comprehensive System Logging"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Verifying system logging configuration..."

# Verify System Log API is accessible and returning events
info "5.1 Testing System Log API access..."
LOG_RESPONSE=$(okta_get "/api/v1/logs?limit=1" 2>/dev/null || echo "[]")
LOG_COUNT=$(echo "${LOG_RESPONSE}" | jq 'length' 2>/dev/null || echo "0")

if [ "${LOG_COUNT}" -gt 0 ]; then
  LATEST_EVENT=$(echo "${LOG_RESPONSE}" | jq -r '.[0] | "\(.eventType) at \(.published)"' 2>/dev/null || echo "unknown")
  pass "5.1 System Log API accessible -- latest event: ${LATEST_EVENT}"
else
  warn "5.1 System Log API returned no events -- verify API token has log read permissions"
fi

# Check for log streaming integrations
info "5.1 Checking log streaming configuration..."
LOG_STREAMS=$(okta_get "/api/v1/logStreams" 2>/dev/null || echo "[]")
STREAM_COUNT=$(echo "${LOG_STREAMS}" | jq 'length' 2>/dev/null || echo "0")

if [ "${STREAM_COUNT}" -gt 0 ]; then
  pass "5.1 Found ${STREAM_COUNT} log stream(s) configured"
  echo "${LOG_STREAMS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status))"' 2>/dev/null || true
else
  warn "5.1 No log streaming configured -- set up SIEM integration via Reports > Log Streaming"
  warn "5.1 DISA STIG V-273202 (HIGH): Centralized audit logging is required"
fi

increment_applied

summary
