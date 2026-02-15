#!/usr/bin/env bash
# HTH GitHub Control 3.04: Restrict Org Actions Permissions
# Profile: L1 | NIST: CM-7, SA-12
# https://howtoharden.com/guides/github/#34-restrict-org-actions-permissions
source "$(dirname "$0")/common.sh"

banner "3.04: Restrict Org Actions Permissions"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.04 Checking org-level Actions permissions for ${GITHUB_ORG}..."

# Idempotency check -- verify org actions are not set to 'all'
ACTIONS_DATA=$(gh_get "/orgs/${GITHUB_ORG}/actions/permissions") || {
  fail "3.04 Unable to retrieve org Actions permissions"
  increment_failed
  summary
  exit 0
}

ALLOWED=$(echo "${ACTIONS_DATA}" | jq -r '.allowed_actions // "all"')

if [ "${ALLOWED}" != "all" ]; then
  pass "3.04 Org Actions are already restricted (allowed_actions: ${ALLOWED})"
  increment_applied
  summary
  exit 0
fi

warn "3.04 Org Actions allow all sources (allowed_actions: ${ALLOWED})"

# HTH Guide Excerpt: begin api-restrict-org-actions
# Restrict organization-level GitHub Actions to selected (verified) creators only
info "3.04 Restricting org-level Actions to selected creators..."
RESPONSE=$(gh_put "/orgs/${GITHUB_ORG}/actions/permissions" '{
  "enabled_repositories": "all",
  "allowed_actions": "selected"
}') || {
  fail "3.04 Failed to restrict org Actions permissions"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-restrict-org-actions

# Verify the change
VERIFY=$(gh_get "/orgs/${GITHUB_ORG}/actions/permissions" 2>/dev/null)
R_ALLOWED=$(echo "${VERIFY}" | jq -r '.allowed_actions // "all"')

if [ "${R_ALLOWED}" = "selected" ]; then
  pass "3.04 Org Actions restricted to selected creators"
  increment_applied
else
  fail "3.04 Org Actions restriction not confirmed after update (got: ${R_ALLOWED})"
  increment_failed
fi

summary
