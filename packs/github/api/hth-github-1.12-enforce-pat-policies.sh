#!/usr/bin/env bash
# HTH GitHub Control 1.12: Enforce Fine-Grained Personal Access Token Policies
# Profile: L2 | NIST: IA-5, AC-6
# https://howtoharden.com/guides/github/#16-enforce-fine-grained-pat-policies
source "$(dirname "$0")/common.sh"

banner "1.12: Enforce Fine-Grained PAT Policies"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.12 Auditing personal access tokens for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-audit-fine-grained-pats
# List all fine-grained PATs with access to the organization
info "1.12 Listing fine-grained PATs with org access..."
PATS=$(gh_get "/orgs/${GITHUB_ORG}/personal-access-tokens?per_page=100") || {
  fail "1.12 Unable to list fine-grained PATs (requires org admin permissions)"
  increment_failed
  summary
  exit 0
}

PAT_COUNT=$(echo "${PATS}" | jq '. | length')
info "1.12 Found ${PAT_COUNT} fine-grained PAT(s) with org access"

# Check for PATs with excessive permissions
echo "${PATS}" | jq -r '.[] | "\(.owner.login) | \(.token_name) | expires: \(.token_expired_at // "never") | repos: \(.repository_selection)"'

# List pending PAT requests requiring approval
info "1.12 Listing pending fine-grained PAT requests..."
REQUESTS=$(gh_get "/orgs/${GITHUB_ORG}/personal-access-token-requests?per_page=100") || {
  warn "1.12 Unable to list PAT requests"
}

if [ -n "${REQUESTS}" ]; then
  REQ_COUNT=$(echo "${REQUESTS}" | jq '. | length')
  if [ "${REQ_COUNT}" -gt "0" ]; then
    warn "1.12 ${REQ_COUNT} pending PAT request(s) awaiting approval"
    echo "${REQUESTS}" | jq -r '.[] | "\(.owner.login) | \(.token_name) | requested: \(.created_at)"'
  else
    pass "1.12 No pending PAT requests"
  fi
fi
# HTH Guide Excerpt: end api-audit-fine-grained-pats

if [ "${PAT_COUNT}" -ge "0" ]; then
  pass "1.12 PAT audit complete -- review results above"
  increment_applied
else
  fail "1.12 Unable to parse PAT data"
  increment_failed
fi

summary
