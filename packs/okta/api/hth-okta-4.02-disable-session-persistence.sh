#!/usr/bin/env bash
# HTH Okta Control 4.2: Disable Session Persistence
# Profile: L2 | NIST: SC-23 | DISA STIG: V-273206
# https://howtoharden.com/guides/okta/#42-disable-session-persistence
source "$(dirname "$0")/common.sh"

banner "4.2: Disable Session Persistence"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.2 Checking session persistence settings..."

# HTH Guide Excerpt: begin api-check-session-persistence
POLICIES=$(okta_get "/api/v1/policies?type=OKTA_SIGN_ON") || {
  fail "4.2 Failed to retrieve global session policies"
  increment_failed
  summary
  exit 0
}

persistent_found=false

for POLICY_ID in $(echo "${POLICIES}" | jq -r '.[].id' 2>/dev/null); do
  RULES=$(okta_get "/api/v1/policies/${POLICY_ID}/rules" 2>/dev/null || echo "[]")
  PERSISTENT=$(echo "${RULES}" | jq '[.[] | select(.actions.signon.session.usePersistentCookie == true)] | length' 2>/dev/null || echo "0")

  if [ "${PERSISTENT}" -gt 0 ]; then
    persistent_found=true
    POLICY_NAME=$(echo "${POLICIES}" | jq -r ".[] | select(.id == \"${POLICY_ID}\") | .name" 2>/dev/null || echo "unknown")
    warn "4.2 Found ${PERSISTENT} rule(s) with persistent sessions in policy '${POLICY_NAME}' (${POLICY_ID})"
  fi
done
# HTH Guide Excerpt: end api-check-session-persistence

if [ "${persistent_found}" = false ]; then
  pass "4.2 No persistent sessions detected"
else
  warn "4.2 Disable persistent sessions: Security > Global Session Policy > Edit rule > Disable persistent cookie"
  warn "4.2 Also check: Customizations > Other > 'Allow users to remain signed in' should be disabled"
fi

increment_applied

summary
