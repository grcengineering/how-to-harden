#!/usr/bin/env bash
# HTH GitHub Control 5.04: Audit Outside Collaborators
# Profile: L2 | NIST: AC-2, AC-6, PS-4
# https://howtoharden.com/guides/github/#54-audit-outside-collaborators
source "$(dirname "$0")/common.sh"

banner "5.04: Audit Outside Collaborators (Audit Only)"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.04 Auditing outside collaborators for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-audit-outside-collaborators
# Audit: List all outside collaborators in the organization
COLLABORATORS=$(gh_get "/orgs/${GITHUB_ORG}/outside_collaborators?per_page=100") || {
  fail "5.04 Unable to retrieve outside collaborators (may require members:read scope)"
  increment_failed
  summary
  exit 0
}

COLLAB_COUNT=$(echo "${COLLABORATORS}" | jq '. | length' 2>/dev/null || echo "0")

info "5.04 Found ${COLLAB_COUNT} outside collaborator(s)"

if [ "${COLLAB_COUNT}" -gt 0 ]; then
  warn "5.04 Outside collaborators with repository access:"
  echo "${COLLABORATORS}" | jq -r '.[] | "  Login: \(.login) | ID: \(.id) | Site Admin: \(.site_admin)"' 2>/dev/null
fi
# HTH Guide Excerpt: end api-audit-outside-collaborators

if [ "${COLLAB_COUNT}" = "0" ]; then
  pass "5.04 No outside collaborators found"
  increment_applied
else
  warn "5.04 ${COLLAB_COUNT} outside collaborator(s) found -- review and remove unnecessary access"
  warn "5.04 Consider converting long-term collaborators to org members with appropriate teams"
  increment_failed
fi

summary
