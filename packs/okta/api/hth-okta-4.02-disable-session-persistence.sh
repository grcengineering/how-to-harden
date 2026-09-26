#!/usr/bin/env bash
# HTH Okta Control 4.2: Disable Session Persistence
# Profile: L2 | NIST: SC-23 | DISA STIG: V-273206
# https://howtoharden.com/guides/okta/#42-disable-session-persistence
#
# Read-only audit of Global Session Policy rules for persistent session cookies.
source "$(dirname "$0")/common.sh"

banner "4.2: Disable Session Persistence"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.2 Checking session persistence settings..."

# HTH Guide Excerpt: begin api-check-session-persistence
# A failed read stops the pack -- an unread rule is never reported as compliant
POLICIES=$(okta_get "/api/v1/policies?type=OKTA_SIGN_ON")

persistent_found=false

for POLICY_ID in $(printf '%s' "${POLICIES}" | jq -r '.[].id'); do
  RULES=$(okta_get "/api/v1/policies/${POLICY_ID}/rules")
  PERSISTENT=$(printf '%s' "${RULES}" | jq '[.[] | select(.actions.signon.session.usePersistentCookie == true)] | length')

  if [ "${PERSISTENT}" -gt 0 ]; then
    persistent_found=true
    POLICY_NAME=$(printf '%s' "${POLICIES}" | jq -r --arg id "${POLICY_ID}" '.[] | select(.id == $id) | .name')
    warn "4.2 Found ${PERSISTENT} rule(s) with persistent sessions in policy '${POLICY_NAME}' (${POLICY_ID})"
  fi
done
# HTH Guide Excerpt: end api-check-session-persistence

if [ "${persistent_found}" = false ]; then
  pass "4.2 No persistent sessions detected"
else
  warn "4.2 Disable persistent sessions: Security > Global Session Policy > rule > Edit > 'Okta global session cookies persist across browser sessions': Disable"
  warn "4.2 Also check: Security > General > Organization Security > 'Show option to stay signed in before users sign in' should be Not Enabled"
fi

increment_applied

summary
