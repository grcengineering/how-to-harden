#!/usr/bin/env bash
# HTH GitHub Control 1.04: Disable Private Repository Forking
# Profile: L2 | NIST: AC-4, AC-6
# https://howtoharden.com/guides/github/#14-disable-private-repository-forking
source "$(dirname "$0")/common.sh"

banner "1.04: Disable Private Repository Forking"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.04 Checking private repository forking settings..."

# Idempotency check -- verify forking of private repos is disabled
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.04 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}

FORK_PRIVATE=$(echo "${ORG_DATA}" | jq -r '.members_can_fork_private_repositories // "unknown"')

if [ "${FORK_PRIVATE}" = "false" ]; then
  pass "1.04 Private repository forking is already disabled"
  increment_applied
  summary
  exit 0
fi

warn "1.04 Members can fork private repositories (current: ${FORK_PRIVATE})"

# HTH Guide Excerpt: begin api-disable-private-forking
# Disable member ability to fork private repositories
info "1.04 Disabling private repository forking..."
RESPONSE=$(gh_patch "/orgs/${GITHUB_ORG}" '{
  "members_can_fork_private_repositories": false
}') || {
  fail "1.04 Failed to disable private repository forking"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-disable-private-forking

RESULT=$(echo "${RESPONSE}" | jq -r '.members_can_fork_private_repositories // "unknown"')
if [ "${RESULT}" = "false" ]; then
  pass "1.04 Private repository forking disabled"
  increment_applied
else
  fail "1.04 Private forking not confirmed as disabled after update"
  increment_failed
fi

summary
