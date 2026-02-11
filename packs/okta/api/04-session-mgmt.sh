#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 4: Session Management
# Controls: 4.1, 4.2, 4.3
# https://howtoharden.com/guides/okta/#4-session-management
source "$(dirname "$0")/common.sh"

banner "Section 4: Session Management"

# ===========================================================================
# 4.1 Configure Session Timeouts
# Profile: L1 | NIST: AC-12, SC-10 | DISA STIG: V-273186, V-273187, V-273203
# ===========================================================================
control_4_1() {
  should_apply 1 || { increment_skipped; return 0; }
  info "4.1 Configuring session timeouts..."

  # Determine settings based on profile level
  local MAX_SESSION="12 hours"
  local MAX_IDLE="1 hour"
  local ADMIN_IDLE="30 minutes"

  if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
    MAX_SESSION="8 hours"
    MAX_IDLE="30 minutes"
    ADMIN_IDLE="15 minutes"
  fi

  if [ "${HTH_PROFILE_LEVEL}" -ge 3 ]; then
    MAX_SESSION="18 hours"
    MAX_IDLE="15 minutes"
    ADMIN_IDLE="15 minutes"
  fi

  info "4.1 Target settings for L${HTH_PROFILE_LEVEL}: max session=${MAX_SESSION}, max idle=${MAX_IDLE}, admin idle=${ADMIN_IDLE}"

  # Get global session policies and report current settings
  POLICIES=$(okta_get "/api/v1/policies?type=OKTA_SIGN_ON") || {
    fail "4.1 Failed to retrieve global session policies"
    increment_failed
    return 0
  }

  POLICY_COUNT=$(echo "${POLICIES}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${POLICY_COUNT}" -eq 0 ]; then
    warn "4.1 No global session policies found"
    increment_skipped
    return 0
  fi

  for POLICY_ID in $(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null); do
    POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
    info "4.1 Reviewing session policy '${POLICY_NAME}' (${POLICY_ID})..."

    RULES=$(okta_get "/api/v1/policies/${POLICY_ID}/rules" 2>/dev/null || echo "[]")
    RULE_COUNT=$(echo "${RULES}" | jq 'length' 2>/dev/null || echo "0")

    if [ "${RULE_COUNT}" -gt 0 ]; then
      echo "${RULES}" | jq -r '.[] | "  - Rule: \(.name), MaxLifetime: \(.actions.signon.session.maxSessionLifetimeMinutes // "default")min, MaxIdle: \(.actions.signon.session.maxSessionIdleMinutes // "default")min, Persistent: \(.actions.signon.session.usePersistentCookie // "default")"' 2>/dev/null || true
    fi
  done

  pass "4.1 Session policies reviewed (${POLICY_COUNT} policy/policies) -- verify settings match L${HTH_PROFILE_LEVEL} targets above"
  warn "4.1 NOTE: Global session policies are best configured via ClickOps or Terraform for full control"
  increment_applied
}

# ===========================================================================
# 4.2 Disable Session Persistence
# Profile: L2 | NIST: SC-23 | DISA STIG: V-273206
# ===========================================================================
control_4_2() {
  should_apply 2 || { increment_skipped; return 0; }
  info "4.2 Checking session persistence settings..."

  POLICIES=$(okta_get "/api/v1/policies?type=OKTA_SIGN_ON") || {
    fail "4.2 Failed to retrieve global session policies"
    increment_failed
    return 0
  }

  local persistent_found=false

  for POLICY_ID in $(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null); do
    RULES=$(okta_get "/api/v1/policies/${POLICY_ID}/rules" 2>/dev/null || echo "[]")
    PERSISTENT=$(echo "${RULES}" | jq '[.[] | select(.actions.signon.session.usePersistentCookie == true)] | length' 2>/dev/null || echo "0")

    if [ "${PERSISTENT}" -gt 0 ]; then
      persistent_found=true
      POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
      warn "4.2 Found ${PERSISTENT} rule(s) with persistent sessions in policy '${POLICY_NAME}' (${POLICY_ID})"
    fi
  done

  if [ "${persistent_found}" = false ]; then
    pass "4.2 No persistent sessions detected"
  else
    warn "4.2 Disable persistent sessions: Security > Global Session Policy > Edit rule > Disable persistent cookie"
    warn "4.2 Also check: Customizations > Other > 'Allow users to remain signed in' should be disabled"
  fi

  increment_applied
}

# ===========================================================================
# 4.3 Configure Admin Session Security
# Profile: L1 | NIST: SC-23, AC-12
# ===========================================================================
control_4_3() {
  should_apply 1 || { increment_skipped; return 0; }
  info "4.3 Configuring admin session security..."

  # Check current admin session settings
  info "4.3 Checking admin session ASN and IP binding..."
  ORG_SETTINGS=$(okta_get "/api/v1/org/settings" 2>/dev/null || echo "{}")

  ASN_BINDING=$(echo "${ORG_SETTINGS}" | jq -r '.adminSessionASNBinding // "unknown"' 2>/dev/null || echo "unknown")
  IP_BINDING=$(echo "${ORG_SETTINGS}" | jq -r '.adminSessionIPBinding // "unknown"' 2>/dev/null || echo "unknown")

  info "4.3 Current ASN binding: ${ASN_BINDING}"
  info "4.3 Current IP binding: ${IP_BINDING}"

  # Determine target settings
  local asn_target="ENABLED"
  local ip_target="${IP_BINDING}"

  if [ "${HTH_PROFILE_LEVEL}" -ge 2 ]; then
    ip_target="ENABLED"
  fi

  # Update if needed
  if [ "${ASN_BINDING}" = "ENABLED" ] && { [ "${HTH_PROFILE_LEVEL}" -lt 2 ] || [ "${IP_BINDING}" = "ENABLED" ]; }; then
    pass "4.3 Admin session binding already configured correctly"
    increment_applied
    return 0
  fi

  info "4.3 Updating admin session binding settings..."
  okta_put "/api/v1/org/settings" "{
    \"adminSessionASNBinding\": \"${asn_target}\",
    \"adminSessionIPBinding\": \"${ip_target}\"
  }" > /dev/null 2>&1 && {
    pass "4.3 Admin session security updated (ASN: ${asn_target}, IP: ${ip_target})"
    increment_applied
  } || {
    fail "4.3 Failed to update admin session settings"
    increment_failed
  }

  info "4.3 Additionally, enable Protected Actions via: Security > General > Protected Actions"
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_4_1
control_4_2
control_4_3

summary
