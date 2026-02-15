#!/usr/bin/env bash
# HTH GitHub Control 3.01: Enable Branch Protection on Default Branch
# Profile: L1 | NIST: CM-3, CM-5
# https://howtoharden.com/guides/github/#31-enable-branch-protection
source "$(dirname "$0")/common.sh"

banner "3.01: Enable Branch Protection on Default Branch"
should_apply 1 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.01 Checking branch protection on ${GITHUB_ORG}/${REPO}..."

# Determine default branch name
REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
  fail "3.01 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

DEFAULT_BRANCH=$(echo "${REPO_DATA}" | jq -r '.default_branch // "main"')
info "3.01 Default branch: ${DEFAULT_BRANCH}"

# Idempotency check -- verify branch protection already exists
PROTECTION=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/branches/${DEFAULT_BRANCH}/protection" 2>/dev/null) && {
  HAS_URL=$(echo "${PROTECTION}" | jq -r 'has("url")' 2>/dev/null || echo "false")
  if [ "${HAS_URL}" = "true" ]; then
    pass "3.01 Branch protection is already enabled on '${DEFAULT_BRANCH}'"
    increment_applied
    summary
    exit 0
  fi
}

warn "3.01 No branch protection found on '${DEFAULT_BRANCH}'"

# HTH Guide Excerpt: begin api-enable-branch-protection
# Enable branch protection with required reviews, dismiss stale, and enforce admins
info "3.01 Enabling branch protection on '${DEFAULT_BRANCH}'..."
RESPONSE=$(gh_put "/repos/${GITHUB_ORG}/${REPO}/branches/${DEFAULT_BRANCH}/protection" '{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null
}') || {
  fail "3.01 Failed to enable branch protection"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-branch-protection

HAS_URL=$(echo "${RESPONSE}" | jq -r 'has("url")' 2>/dev/null || echo "false")
if [ "${HAS_URL}" = "true" ]; then
  pass "3.01 Branch protection enabled on '${DEFAULT_BRANCH}'"
  increment_applied
else
  fail "3.01 Branch protection not confirmed after update"
  increment_failed
fi

summary
