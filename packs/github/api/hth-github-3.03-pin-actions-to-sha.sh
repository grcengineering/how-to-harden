#!/usr/bin/env bash
# HTH GitHub Control 3.03: Pin Actions to SHA
# Profile: L2 | NIST: SA-12, SI-7
# https://howtoharden.com/guides/github/#33-pin-actions-to-sha
source "$(dirname "$0")/common.sh"

banner "3.03: Pin Actions to SHA (Audit Only)"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.03 Auditing Actions SHA pinning on ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-audit-sha-pinning
# Audit: Check workflow files for actions not pinned to full SHA
# Note: SHA pinning cannot be enforced via API -- workflows must be manually updated
# Recommended tool: npx pin-github-action .github/workflows/*.yml
info "3.03 Retrieving workflow files..."
WORKFLOWS=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/contents/.github/workflows" 2>/dev/null) || {
  warn "3.03 No .github/workflows directory found -- no workflows to audit"
  increment_applied
  summary
  exit 0
}

WORKFLOW_COUNT=$(echo "${WORKFLOWS}" | jq '. | length' 2>/dev/null || echo "0")
info "3.03 Found ${WORKFLOW_COUNT} workflow file(s)"

if [ "${WORKFLOW_COUNT}" = "0" ]; then
  pass "3.03 No workflow files found -- nothing to pin"
  increment_applied
  summary
  exit 0
fi

# Check each workflow for tag-based action references (not SHA-pinned)
UNPINNED=0
for NAME in $(echo "${WORKFLOWS}" | jq -r '.[].name' 2>/dev/null); do
  CONTENT=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/contents/.github/workflows/${NAME}" \
    | jq -r '.content // empty' 2>/dev/null | base64 -d 2>/dev/null || true)
  if [ -n "${CONTENT}" ]; then
    # Look for uses: owner/action@v* or @tag patterns (not 40-char SHA)
    TAG_REFS=$(echo "${CONTENT}" | grep -cE 'uses:\s+\S+@v[0-9]' 2>/dev/null || true)
    if [ "${TAG_REFS}" -gt 0 ] 2>/dev/null; then
      warn "3.03 ${NAME}: ${TAG_REFS} action(s) pinned to tag instead of SHA"
      UNPINNED=$((UNPINNED + TAG_REFS))
    fi
  fi
done
# HTH Guide Excerpt: end api-audit-sha-pinning

if [ "${UNPINNED}" -gt 0 ]; then
  warn "3.03 ${UNPINNED} total action reference(s) not pinned to SHA"
  warn "3.03 Run: npx pin-github-action .github/workflows/*.yml"
  increment_failed
else
  pass "3.03 All actions appear to be SHA-pinned"
  increment_applied
fi

summary
