#!/usr/bin/env bash
# HTH Okta Control 4.1: Configure Session Timeouts
# Profile: L1 | NIST: AC-12, SC-10 | DISA STIG: V-273186, V-273187, V-273203
# https://howtoharden.com/guides/okta/#41-configure-session-timeouts
source "$(dirname "$0")/common.sh"

banner "4.1: Configure Session Timeouts"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Configuring session timeouts..."

# Determine settings based on profile level
MAX_SESSION="12 hours"
MAX_IDLE="1 hour"
ADMIN_IDLE="30 minutes"

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

# HTH Guide Excerpt: begin api-check-session-policies
# Get global session policies and report current settings
POLICIES=$(okta_get "/api/v1/policies?type=OKTA_SIGN_ON") || {
  fail "4.1 Failed to retrieve global session policies"
  increment_failed
  summary
  exit 0
}

POLICY_COUNT=$(echo "${POLICIES}" | jq 'length' 2>/dev/null || echo "0")

if [ "${POLICY_COUNT}" -eq 0 ]; then
  warn "4.1 No global session policies found"
  increment_skipped
  summary
  exit 0
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
# HTH Guide Excerpt: end api-check-session-policies

pass "4.1 Session policies reviewed (${POLICY_COUNT} policy/policies) -- verify settings match L${HTH_PROFILE_LEVEL} targets above"
warn "4.1 NOTE: Global session policies are best configured via ClickOps or Terraform for full control"
increment_applied

summary
