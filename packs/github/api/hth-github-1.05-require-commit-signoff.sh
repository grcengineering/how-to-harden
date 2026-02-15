#!/usr/bin/env bash
# HTH GitHub Control 1.05: Require Web Commit Sign-Off
# Profile: L2 | NIST: AU-10, CM-5
# https://howtoharden.com/guides/github/#15-require-commit-sign-off
source "$(dirname "$0")/common.sh"

banner "1.05: Require Web Commit Sign-Off"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.05 Checking web commit sign-off requirement..."

# Idempotency check -- verify org requires web commit sign-off
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.05 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}

SIGNOFF=$(echo "${ORG_DATA}" | jq -r '.web_commit_signoff_required // false')

if [ "${SIGNOFF}" = "true" ]; then
  pass "1.05 Web commit sign-off is already required"
  increment_applied
  summary
  exit 0
fi

warn "1.05 Web commit sign-off is not required (current: ${SIGNOFF})"

# HTH Guide Excerpt: begin api-require-signoff
# Enable web commit sign-off requirement at the organization level
info "1.05 Enabling web commit sign-off requirement..."
RESPONSE=$(gh_patch "/orgs/${GITHUB_ORG}" '{
  "web_commit_signoff_required": true
}') || {
  fail "1.05 Failed to enable web commit sign-off requirement"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-require-signoff

RESULT=$(echo "${RESPONSE}" | jq -r '.web_commit_signoff_required // false')
if [ "${RESULT}" = "true" ]; then
  pass "1.05 Web commit sign-off requirement enabled"
  increment_applied
else
  fail "1.05 Web commit sign-off not confirmed after update"
  increment_failed
fi

summary
