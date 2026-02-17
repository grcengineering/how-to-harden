#!/usr/bin/env bash
# HTH Salesforce Control 5.1: Enable Event Monitoring for API Anomalies
# Profile: L1 | NIST: AU-2, AU-6, SI-4
# https://howtoharden.com/guides/salesforce/#51-enable-event-monitoring-for-api-anomalies
source "$(dirname "$0")/common.sh"

banner "5.1: Enable Event Monitoring for API Anomalies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.1 Auditing Event Monitoring configuration and recent event logs..."

# HTH Guide Excerpt: begin api-check-event-log-files
# Query available EventLogFile types to verify Event Monitoring is active
info "5.1 Checking EventLogFile availability..."
LOG_QUERY="SELECT Id, EventType, LogDate, LogFileLength FROM EventLogFile ORDER BY LogDate DESC LIMIT 50"
LOG_RESPONSE=$(sf_query "${LOG_QUERY}") || {
  fail "5.1 Failed to query EventLogFile -- Event Monitoring may not be enabled"
  fail "5.1 Enable via Setup > Event Monitoring Settings or purchase Salesforce Shield"
  increment_failed
  summary
  exit 0
}

LOG_COUNT=$(echo "${LOG_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${LOG_COUNT}" -gt 0 ]; then
  pass "5.1 Event Monitoring is active -- found ${LOG_COUNT} recent log file(s)"

  # Summarize event types available
  EVENT_TYPES=$(echo "${LOG_RESPONSE}" | jq -r '[.records[].EventType] | unique | sort | .[]' 2>/dev/null || true)
  TYPE_COUNT=$(echo "${EVENT_TYPES}" | grep -c . 2>/dev/null || echo "0")
  info "5.1 ${TYPE_COUNT} event type(s) available:"
  echo "${EVENT_TYPES}" | while read -r etype; do
    echo "  - ${etype}"
  done
else
  warn "5.1 No EventLogFile records found -- Event Monitoring may not be enabled"
  warn "5.1 Enable via Setup > Event Monitoring Settings"
fi
# HTH Guide Excerpt: end api-check-event-log-files

# HTH Guide Excerpt: begin api-check-api-anomaly-events
# Look for API-related event types indicating anomaly detection
info "5.1 Checking for API anomaly event types..."
API_LOG_QUERY="SELECT Id, EventType, LogDate, LogFileLength FROM EventLogFile WHERE EventType IN ('ApiTotalUsage', 'API', 'RestApi', 'BulkApi', 'Login', 'LoginAs') ORDER BY LogDate DESC LIMIT 20"
API_LOG_RESPONSE=$(sf_query "${API_LOG_QUERY}" 2>/dev/null || echo '{"records":[],"totalSize":0}')

API_LOG_COUNT=$(echo "${API_LOG_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${API_LOG_COUNT}" -gt 0 ]; then
  pass "5.1 Found ${API_LOG_COUNT} API-related event log(s)"
  echo "${API_LOG_RESPONSE}" | jq -r '.records[] | "  - \(.EventType) on \(.LogDate) (\(.LogFileLength) bytes)"' 2>/dev/null || true
else
  warn "5.1 No API-related event logs found -- enable API event types in Event Monitoring"
fi
# HTH Guide Excerpt: end api-check-api-anomaly-events

# HTH Guide Excerpt: begin api-audit-failed-logins
# Audit recent failed login attempts for suspicious activity
info "5.1 Auditing recent failed login attempts..."
FAILED_QUERY="SELECT Id, LoginTime, SourceIp, Status, Application, UserId, LoginType FROM LoginHistory WHERE Status = 'Failed' ORDER BY LoginTime DESC LIMIT 50"
FAILED_RESPONSE=$(sf_query "${FAILED_QUERY}" 2>/dev/null || echo '{"records":[],"totalSize":0}')

FAILED_COUNT=$(echo "${FAILED_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${FAILED_COUNT}" -gt 0 ]; then
  warn "5.1 Found ${FAILED_COUNT} recent failed login attempt(s):"

  # Group by source IP for anomaly detection
  UNIQUE_FAIL_IPS=$(echo "${FAILED_RESPONSE}" | jq -r '[.records[].SourceIp] | unique | .[]' 2>/dev/null || true)
  echo "${UNIQUE_FAIL_IPS}" | while read -r ip; do
    COUNT=$(echo "${FAILED_RESPONSE}" | jq "[.records[] | select(.SourceIp == \"${ip}\")] | length" 2>/dev/null || echo "?")
    echo "  - ${ip}: ${COUNT} failed attempt(s)"
  done

  # Flag IPs with 5+ failures (brute force indicator)
  echo "${UNIQUE_FAIL_IPS}" | while read -r ip; do
    COUNT=$(echo "${FAILED_RESPONSE}" | jq "[.records[] | select(.SourceIp == \"${ip}\")] | length" 2>/dev/null || echo "0")
    if [ "${COUNT}" -ge 5 ]; then
      warn "5.1 ALERT: ${ip} has ${COUNT} failed logins -- possible brute force"
    fi
  done
else
  pass "5.1 No recent failed login attempts found"
fi
# HTH Guide Excerpt: end api-audit-failed-logins

increment_applied

summary
