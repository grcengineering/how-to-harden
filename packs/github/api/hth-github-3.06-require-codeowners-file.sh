#!/usr/bin/env bash
# HTH GitHub Control 3.06: Require CODEOWNERS File
# Profile: L2 | NIST: CM-3, CM-5
# https://howtoharden.com/guides/github/#36-require-codeowners-file
source "$(dirname "$0")/common.sh"

banner "3.06: Require CODEOWNERS File (Audit Only)"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.06 Auditing CODEOWNERS file on ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-audit-codeowners
# Audit: Check for CODEOWNERS file in standard locations
# Note: CODEOWNERS must be committed to the repo -- cannot be created via API
FOUND=false

for LOCATION in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
  CONTENT=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/contents/${LOCATION}" 2>/dev/null) || continue
  HAS_NAME=$(echo "${CONTENT}" | jq -r 'has("name")' 2>/dev/null || echo "false")
  if [ "${HAS_NAME}" = "true" ]; then
    pass "3.06 CODEOWNERS file found at ${LOCATION}"
    FOUND=true
    break
  fi
done
# HTH Guide Excerpt: end api-audit-codeowners

if [ "${FOUND}" = "true" ]; then
  increment_applied
else
  fail "3.06 No CODEOWNERS file found in .github/, root, or docs/"
  warn "3.06 Create a CODEOWNERS file and commit it to the repository"
  warn "3.06 Example: echo '* @${GITHUB_ORG}/security-team' > .github/CODEOWNERS"
  increment_failed
fi

summary
