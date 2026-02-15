#!/usr/bin/env bash
# HTH GitHub Control 3.02: Restrict Actions to Verified Creators
# Profile: L2 | NIST: CM-7, SA-12
# https://howtoharden.com/guides/github/#32-restrict-actions-to-verified-creators
source "$(dirname "$0")/common.sh"

banner "3.02: Restrict Actions to Verified Creators"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.02 Checking Actions permissions on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify actions are not set to 'all'
ACTIONS_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/actions/permissions") || {
  fail "3.02 Unable to retrieve Actions permissions for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

ALLOWED=$(echo "${ACTIONS_DATA}" | jq -r '.allowed_actions // "all"')
ENABLED=$(echo "${ACTIONS_DATA}" | jq -r '.enabled // false')

if [ "${ALLOWED}" != "all" ] || [ "${ENABLED}" = "false" ]; then
  pass "3.02 Actions are already restricted (allowed_actions: ${ALLOWED}, enabled: ${ENABLED})"
  increment_applied
  summary
  exit 0
fi

warn "3.02 Actions allow all sources (allowed_actions: ${ALLOWED})"

# HTH Guide Excerpt: begin api-restrict-actions
# Restrict GitHub Actions to only selected (verified) creators
info "3.02 Restricting Actions to selected creators..."
RESPONSE=$(gh_put "/repos/${GITHUB_ORG}/${REPO}/actions/permissions" '{
  "enabled": true,
  "allowed_actions": "selected"
}') || {
  fail "3.02 Failed to restrict Actions permissions"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-restrict-actions

# Verify the change
VERIFY=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/actions/permissions" 2>/dev/null)
R_ALLOWED=$(echo "${VERIFY}" | jq -r '.allowed_actions // "all"')

if [ "${R_ALLOWED}" = "selected" ]; then
  pass "3.02 Actions restricted to selected creators"
  increment_applied
else
  fail "3.02 Actions restriction not confirmed after update (got: ${R_ALLOWED})"
  increment_failed
fi

summary
