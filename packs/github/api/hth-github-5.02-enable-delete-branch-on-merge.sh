#!/usr/bin/env bash
# HTH GitHub Control 5.02: Enable Delete Branch on Merge
# Profile: L2 | NIST: CM-3
# https://howtoharden.com/guides/github/#52-enable-delete-branch-on-merge
source "$(dirname "$0")/common.sh"

banner "5.02: Enable Delete Branch on Merge"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "5.02 Checking delete-branch-on-merge on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify delete_branch_on_merge is true
REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
  fail "5.02 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

DELETE_ON_MERGE=$(echo "${REPO_DATA}" | jq -r '.delete_branch_on_merge // false')

if [ "${DELETE_ON_MERGE}" = "true" ]; then
  pass "5.02 Delete branch on merge is already enabled"
  increment_applied
  summary
  exit 0
fi

warn "5.02 Delete branch on merge is disabled"

# HTH Guide Excerpt: begin api-enable-delete-branch-on-merge
# Enable automatic branch deletion after pull request merge
info "5.02 Enabling delete branch on merge..."
RESPONSE=$(gh_patch "/repos/${GITHUB_ORG}/${REPO}" '{
  "delete_branch_on_merge": true
}') || {
  fail "5.02 Failed to enable delete branch on merge"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-delete-branch-on-merge

RESULT=$(echo "${RESPONSE}" | jq -r '.delete_branch_on_merge // false')
if [ "${RESULT}" = "true" ]; then
  pass "5.02 Delete branch on merge enabled"
  increment_applied
else
  fail "5.02 Delete branch on merge not confirmed after update"
  increment_failed
fi

summary
