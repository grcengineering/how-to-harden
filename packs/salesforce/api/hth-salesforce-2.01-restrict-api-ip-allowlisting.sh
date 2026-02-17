#!/usr/bin/env bash
# HTH Salesforce Control 2.1: Restrict API Access via IP Allowlisting
# Profile: L1 | NIST: AC-3, SC-7
# https://howtoharden.com/guides/salesforce/#21-restrict-api-access-via-ip-allowlisting
source "$(dirname "$0")/common.sh"

banner "2.1: Restrict API Access via IP Allowlisting"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing IP allowlist configuration for API access..."

# HTH Guide Excerpt: begin api-query-login-ip-ranges
# Query all configured Login IP Ranges across profiles
info "2.1 Querying Login IP Ranges by profile..."
IP_QUERY="SELECT Id, ProfileId, Profile.Name, StartAddress, EndAddress, Description FROM LoginIpRange ORDER BY Profile.Name"
IP_RESPONSE=$(sf_query "${IP_QUERY}") || {
  fail "2.1 Failed to query Login IP Ranges"
  increment_failed
  summary
  exit 0
}

RANGE_COUNT=$(echo "${IP_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${RANGE_COUNT}" -gt 0 ]; then
  pass "2.1 Found ${RANGE_COUNT} Login IP Range(s) configured"
  echo "${IP_RESPONSE}" | jq -r '.records[] | "  - Profile: \(.Profile.Name // "unknown") | \(.StartAddress) - \(.EndAddress) | \(.Description // "no description")"' 2>/dev/null || true
else
  warn "2.1 No Login IP Ranges configured -- API access is unrestricted by IP"
  warn "2.1 NIST SC-7: Network boundary protection requires IP-based access controls"
fi
# HTH Guide Excerpt: end api-query-login-ip-ranges

# HTH Guide Excerpt: begin api-check-trusted-ip-ranges
# Query Trusted IP Ranges (org-wide network access)
info "2.1 Checking org-wide Trusted IP Ranges..."
TRUSTED_QUERY="SELECT Id, StartAddress, EndAddress, Description FROM SecuritySettings"
# Trusted IP ranges are in Network Access -- query via Setup API
NETWORK_RESPONSE=$(sf_tooling_query "SELECT Id, StartAddress, EndAddress, Description FROM NetworkAccess" 2>/dev/null || echo '{"records":[]}')

TRUSTED_COUNT=$(echo "${NETWORK_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)

if [ "${TRUSTED_COUNT}" -gt 0 ]; then
  info "2.1 Found ${TRUSTED_COUNT} Trusted IP Range(s) (org-wide):"
  echo "${NETWORK_RESPONSE}" | jq -r '.records[] | "  - \(.StartAddress) - \(.EndAddress) | \(.Description // "no description")"' 2>/dev/null || true
else
  warn "2.1 No org-wide Trusted IP Ranges configured"
fi
# HTH Guide Excerpt: end api-check-trusted-ip-ranges

# HTH Guide Excerpt: begin api-audit-recent-login-ips
# Audit recent login IPs to identify unexpected sources
info "2.1 Auditing recent login source IPs (last 100 logins)..."
LOGIN_QUERY="SELECT Id, UserId, LoginTime, SourceIp, Status, Application, LoginType FROM LoginHistory ORDER BY LoginTime DESC LIMIT 100"
LOGIN_RESPONSE=$(sf_query "${LOGIN_QUERY}" 2>/dev/null || echo '{"records":[]}')

LOGIN_COUNT=$(echo "${LOGIN_RESPONSE}" | jq '.totalSize // 0' 2>/dev/null)
if [ "${LOGIN_COUNT}" -gt 0 ]; then
  # Summarize unique source IPs
  UNIQUE_IPS=$(echo "${LOGIN_RESPONSE}" | jq -r '[.records[].SourceIp] | unique | .[]' 2>/dev/null || true)
  IP_COUNT=$(echo "${UNIQUE_IPS}" | grep -c . 2>/dev/null || echo "0")
  info "2.1 Found ${IP_COUNT} unique source IP(s) in last ${LOGIN_COUNT} logins:"
  echo "${UNIQUE_IPS}" | while read -r ip; do
    COUNT=$(echo "${LOGIN_RESPONSE}" | jq "[.records[] | select(.SourceIp == \"${ip}\")] | length" 2>/dev/null || echo "?")
    echo "  - ${ip} (${COUNT} logins)"
  done

  # Flag failed logins from unexpected IPs
  FAILED=$(echo "${LOGIN_RESPONSE}" | jq '[.records[] | select(.Status == "Failed")]' 2>/dev/null || echo "[]")
  FAILED_COUNT=$(echo "${FAILED}" | jq 'length' 2>/dev/null || echo "0")
  if [ "${FAILED_COUNT}" -gt 0 ]; then
    warn "2.1 Found ${FAILED_COUNT} failed login(s) -- review source IPs:"
    echo "${FAILED}" | jq -r '.[] | "  - \(.SourceIp) at \(.LoginTime) via \(.Application // "unknown")"' 2>/dev/null || true
  fi
else
  warn "2.1 No login history available -- verify API token has login history read permissions"
fi
# HTH Guide Excerpt: end api-audit-recent-login-ips

increment_applied

summary
