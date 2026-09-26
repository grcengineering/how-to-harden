#!/usr/bin/env bash
# HTH Okta Control 4.1: Configure Session Timeouts
# Profile: L1 | NIST: AC-12, SC-10 | DISA STIG: V-273186, V-273187, V-273203
# https://howtoharden.com/guides/okta/#41-configure-session-timeouts
#
# Read-only audit of Global Session Policy rules and the Okta Admin Console
# session settings (GET /api/v1/first-party-app-settings/admin-console).
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
# Get global session policies and report current settings (a failed read stops the pack)
POLICIES=$(okta_get "/api/v1/policies?type=OKTA_SIGN_ON")
POLICY_COUNT=$(printf '%s' "${POLICIES}" | jq 'length')

if [ "${POLICY_COUNT}" -eq 0 ]; then
  fail "4.1 No global session policies returned -- every Okta org has a Default Policy"
  increment_failed
  summary
fi

for POLICY_ID in $(printf '%s' "${POLICIES}" | jq -r '.[].id'); do
  POLICY_NAME=$(printf '%s' "${POLICIES}" | jq -r --arg id "${POLICY_ID}" '.[] | select(.id == $id) | .name')
  info "4.1 Reviewing session policy '${POLICY_NAME}' (${POLICY_ID})..."
  okta_get "/api/v1/policies/${POLICY_ID}/rules" \
    | jq -r '.[] | "  - Rule: \(.name), MaxLifetime: \(.actions.signon.session.maxSessionLifetimeMinutes // "default")min, MaxIdle: \(.actions.signon.session.maxSessionIdleMinutes // "default")min, Persistent: \(.actions.signon.session.usePersistentCookie // "default")"'
done
# HTH Guide Excerpt: end api-check-session-policies

# HTH Guide Excerpt: begin api-check-admin-console-session
# Okta Admin Console session idle time and lifetime
okta_get "/api/v1/first-party-app-settings/admin-console" \
  | jq -r '"  - Admin Console: idle \(.sessionIdleTimeoutMinutes)min, max lifetime \(.sessionMaxLifetimeMinutes)min"'
# HTH Guide Excerpt: end api-check-admin-console-session

pass "4.1 Session policies reviewed (${POLICY_COUNT} policy/policies) -- verify settings match L${HTH_PROFILE_LEVEL} targets above"
increment_applied

summary
