#!/usr/bin/env bash
# HTH GitHub Control 1.03: Restrict Public Repository Creation
# Profile: L1 | NIST: AC-4, AC-22
# https://howtoharden.com/guides/github/#13-restrict-public-repository-creation
source "$(dirname "$0")/common.sh"

banner "1.03: Restrict Public Repository Creation"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.03 Checking public repository creation settings..."

# Idempotency check -- verify members cannot create public repos
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.03 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}

PUBLIC_REPOS=$(echo "${ORG_DATA}" | jq -r '.members_can_create_public_repositories // "unknown"')

if [ "${PUBLIC_REPOS}" = "false" ]; then
  pass "1.03 Public repository creation is already disabled"
  increment_applied
  summary
  exit 0
fi

warn "1.03 Members can create public repositories (current: ${PUBLIC_REPOS})"

# HTH Guide Excerpt: begin api-disable-public-repos
# Disable member ability to create public repositories
info "1.03 Disabling public repository creation..."
RESPONSE=$(gh_patch "/orgs/${GITHUB_ORG}" '{
  "members_can_create_public_repositories": false
}') || {
  fail "1.03 Failed to disable public repository creation"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-disable-public-repos

RESULT=$(echo "${RESPONSE}" | jq -r '.members_can_create_public_repositories // "unknown"')
if [ "${RESULT}" = "false" ]; then
  pass "1.03 Public repository creation disabled"
  increment_applied
else
  fail "1.03 Public repo creation not confirmed as disabled after update"
  increment_failed
fi

summary
