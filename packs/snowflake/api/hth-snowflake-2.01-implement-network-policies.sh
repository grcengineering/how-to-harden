#!/usr/bin/env bash
# HTH Snowflake Control 2.1: Implement Network Policies
# Profile: L1 | NIST: SC-7
# https://howtoharden.com/guides/snowflake/#21-implement-network-policies
source "$(dirname "$0")/common.sh"

banner "2.1: Implement Network Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin audit-network-policies
# Audit existing network policies
info "2.1 Auditing existing network policies..."
EXISTING_POLICIES=$(snow_query "SHOW NETWORK POLICIES;") || {
  warn "2.1 No network policies found or query failed"
  EXISTING_POLICIES="[]"
}

POLICY_COUNT=$(echo "${EXISTING_POLICIES}" | jq 'length' 2>/dev/null || echo "0")

if [ "${POLICY_COUNT}" -gt 0 ]; then
  info "2.1 Found ${POLICY_COUNT} existing network policies:"
  echo "${EXISTING_POLICIES}" | jq -r '.[] | "  - \(.name): allowed=\(.allowed_ip_list // "none"), blocked=\(.blocked_ip_list // "none")"' 2>/dev/null || true
else
  warn "2.1 No network policies configured -- account is accessible from any IP"
fi
# HTH Guide Excerpt: end audit-network-policies

# Create network policy if ALLOWED_IPS is set
if [ -n "${SNOWFLAKE_ALLOWED_IPS:-}" ]; then
  # HTH Guide Excerpt: begin create-network-policy
  info "2.1 Creating network policy with allowed IPs: ${SNOWFLAKE_ALLOWED_IPS}"
  snow_exec "
CREATE NETWORK POLICY IF NOT EXISTS hth_corporate_access
  ALLOWED_IP_LIST = (${SNOWFLAKE_ALLOWED_IPS})
  BLOCKED_IP_LIST = ()
  COMMENT = 'HTH: Restrict access to corporate IPs (Control 2.1)';
" > /dev/null 2>&1 || {
    fail "2.1 Failed to create network policy"
    increment_failed
    summary
    exit 0
  }

  # Activate at account level
  info "2.1 Activating network policy at account level..."
  snow_exec "
ALTER ACCOUNT SET NETWORK_POLICY = 'hth_corporate_access';
" > /dev/null 2>&1 || {
    fail "2.1 Failed to activate network policy (requires ACCOUNTADMIN)"
    increment_failed
    summary
    exit 0
  }
  # HTH Guide Excerpt: end create-network-policy

  pass "2.1 Network policy hth_corporate_access created and activated"
  increment_applied
else
  warn "2.1 Set SNOWFLAKE_ALLOWED_IPS to create a network policy (e.g., '10.0.0.0/8','192.168.1.0/24')"
  if [ "${POLICY_COUNT}" -gt 0 ]; then
    pass "2.1 Existing network policies found -- verify they match your requirements"
    increment_applied
  else
    fail "2.1 No network policies in place and SNOWFLAKE_ALLOWED_IPS not set"
    increment_failed
  fi
fi

# Check for overly permissive policies (0.0.0.0/0)
info "2.1 Checking for overly permissive network policies..."
PERMISSIVE=$(echo "${EXISTING_POLICIES}" | jq '[.[] | select(.allowed_ip_list | test("0\\.0\\.0\\.0/0"))] | length' 2>/dev/null || echo "0")
if [ "${PERMISSIVE}" -gt 0 ]; then
  fail "2.1 Found ${PERMISSIVE} policy(ies) allowing 0.0.0.0/0 -- this defeats the purpose of network policies"
else
  pass "2.1 No overly permissive (0.0.0.0/0) policies detected"
fi

summary
