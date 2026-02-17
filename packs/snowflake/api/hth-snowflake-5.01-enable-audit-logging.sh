#!/usr/bin/env bash
# HTH Snowflake Control 5.1: Enable Comprehensive Audit Logging
# Profile: L1 | NIST: AU-2, AU-3, AU-6
# https://howtoharden.com/guides/snowflake/#51-enable-comprehensive-audit-logging
source "$(dirname "$0")/common.sh"

banner "5.1: Enable Comprehensive Audit Logging"

should_apply 1 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin audit-login-history
# Query recent login history for anomalies
info "5.1 Querying login history (last 24 hours)..."
LOGIN_HISTORY=$(snow_query "
SELECT
    user_name,
    client_ip,
    reported_client_type,
    first_authentication_factor,
    second_authentication_factor,
    is_success,
    error_code,
    error_message,
    event_timestamp
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE event_timestamp > DATEADD('hour', -24, CURRENT_TIMESTAMP())
ORDER BY event_timestamp DESC
LIMIT 500;
") || {
  fail "5.1 Failed to query login history (check ACCOUNTADMIN or SNOWFLAKE database access)"
  increment_failed
  summary
  exit 0
}

TOTAL_LOGINS=$(echo "${LOGIN_HISTORY}" | jq 'length' 2>/dev/null || echo "0")
FAILED_LOGINS=$(echo "${LOGIN_HISTORY}" | jq '[.[] | select(.IS_SUCCESS == "NO")] | length' 2>/dev/null || echo "0")

info "5.1 Last 24h: ${TOTAL_LOGINS} total logins, ${FAILED_LOGINS} failed"

if [ "${FAILED_LOGINS}" -gt 0 ]; then
  warn "5.1 Failed login attempts detected:"
  echo "${LOGIN_HISTORY}" | jq -r '.[] | select(.IS_SUCCESS == "NO") | "  - \(.USER_NAME) from \(.CLIENT_IP) [\(.REPORTED_CLIENT_TYPE)] error: \(.ERROR_MESSAGE)"' 2>/dev/null | head -20 || true
fi
# HTH Guide Excerpt: end audit-login-history

# HTH Guide Excerpt: begin detect-anomalies
# Detect suspicious patterns: off-hours access, unusual clients, brute force
info "5.1 Checking for brute-force patterns..."
BRUTE_FORCE=$(snow_query "
SELECT
    user_name,
    client_ip,
    COUNT(*) AS failed_attempts
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE event_timestamp > DATEADD('hour', -1, CURRENT_TIMESTAMP())
  AND is_success = 'NO'
GROUP BY user_name, client_ip
HAVING COUNT(*) >= 5
ORDER BY failed_attempts DESC;
") || {
  warn "5.1 Could not run brute-force detection query"
  BRUTE_FORCE="[]"
}

BRUTE_COUNT=$(echo "${BRUTE_FORCE}" | jq 'length' 2>/dev/null || echo "0")
if [ "${BRUTE_COUNT}" -gt 0 ]; then
  fail "5.1 Potential brute-force detected (>=5 failures/hour):"
  echo "${BRUTE_FORCE}" | jq -r '.[] | "  - \(.USER_NAME) from \(.CLIENT_IP): \(.FAILED_ATTEMPTS) attempts"' 2>/dev/null || true
else
  pass "5.1 No brute-force patterns detected in the last hour"
fi

# Check for access without MFA
info "5.1 Checking for logins without second factor..."
NO_MFA_LOGINS=$(snow_query "
SELECT
    user_name,
    client_ip,
    first_authentication_factor,
    second_authentication_factor,
    COUNT(*) AS login_count
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE event_timestamp > DATEADD('hour', -24, CURRENT_TIMESTAMP())
  AND is_success = 'YES'
  AND (second_authentication_factor IS NULL OR second_authentication_factor = '')
GROUP BY user_name, client_ip, first_authentication_factor, second_authentication_factor
ORDER BY login_count DESC;
") || {
  warn "5.1 Could not query MFA login data"
  NO_MFA_LOGINS="[]"
}

NO_MFA_COUNT=$(echo "${NO_MFA_LOGINS}" | jq 'length' 2>/dev/null || echo "0")
if [ "${NO_MFA_COUNT}" -gt 0 ]; then
  warn "5.1 ${NO_MFA_COUNT} user(s) logged in without second factor in last 24h"
  echo "${NO_MFA_LOGINS}" | jq -r '.[] | "  - \(.USER_NAME) via \(.FIRST_AUTHENTICATION_FACTOR) (\(.LOGIN_COUNT)x)"' 2>/dev/null | head -10 || true
else
  pass "5.1 All successful logins used a second authentication factor"
fi
# HTH Guide Excerpt: end detect-anomalies

# HTH Guide Excerpt: begin verify-account-usage
# Verify ACCOUNT_USAGE schema is accessible (required for audit)
info "5.1 Verifying ACCOUNT_USAGE schema access..."
snow_query "SELECT COUNT(*) AS cnt FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE start_time > DATEADD('minute', -5, CURRENT_TIMESTAMP());" > /dev/null 2>&1 && {
  pass "5.1 ACCOUNT_USAGE schema is accessible for audit logging"
} || {
  fail "5.1 Cannot access ACCOUNT_USAGE schema -- grant IMPORTED PRIVILEGES on SNOWFLAKE database"
}
# HTH Guide Excerpt: end verify-account-usage

pass "5.1 Audit logging review complete"
increment_applied

summary
