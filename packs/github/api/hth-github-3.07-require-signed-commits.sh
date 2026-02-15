#!/usr/bin/env bash
# HTH GitHub Control 3.07: Require Signed Commits
# Profile: L3 | NIST: AU-10, SC-13
# https://howtoharden.com/guides/github/#37-require-signed-commits
source "$(dirname "$0")/common.sh"

banner "3.07: Require Signed Commits (Audit Only)"
should_apply 3 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.07 Auditing commit signing on ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-audit-signed-commits
# Audit: Check recent commits for GPG/SSH signature verification
# Note: Commit signing is per-developer; enforcement is via branch protection rules
info "3.07 Checking recent commit signatures..."
COMMITS=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/commits?per_page=10") || {
  fail "3.07 Unable to retrieve commits for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

TOTAL=$(echo "${COMMITS}" | jq '. | length' 2>/dev/null || echo "0")
VERIFIED=$(echo "${COMMITS}" | jq '[.[] | select(.commit.verification.verified == true)] | length' 2>/dev/null || echo "0")
UNVERIFIED=$((TOTAL - VERIFIED))

info "3.07 Checked ${TOTAL} recent commits: ${VERIFIED} signed, ${UNVERIFIED} unsigned"

# Check if branch protection enforces signed commits
REPO_META=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || true
DEFAULT_BRANCH=$(echo "${REPO_META}" | jq -r '.default_branch // "main"' 2>/dev/null)

SIGNATURE_REQUIRED="false"
PROTECTION=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/branches/${DEFAULT_BRANCH}/protection/required_signatures" 2>/dev/null) && {
  SIGNATURE_REQUIRED=$(echo "${PROTECTION}" | jq -r '.enabled // false' 2>/dev/null || echo "false")
}
# HTH Guide Excerpt: end api-audit-signed-commits

if [ "${SIGNATURE_REQUIRED}" = "true" ]; then
  pass "3.07 Signed commits are required via branch protection"
  increment_applied
elif [ "${UNVERIFIED}" = "0" ] && [ "${TOTAL}" -gt 0 ]; then
  pass "3.07 All ${TOTAL} recent commits are signed (branch protection not enforcing)"
  warn "3.07 Consider enabling required signatures in branch protection"
  increment_applied
else
  warn "3.07 ${UNVERIFIED} of ${TOTAL} recent commits are unsigned"
  warn "3.07 Enable required signatures via branch protection or per-developer GPG/SSH key setup"
  increment_failed
fi

summary
