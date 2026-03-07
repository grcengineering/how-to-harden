#!/usr/bin/env bash
# HTH GitHub Control 4.08: Enforce Fine-Grained Personal Access Tokens
# Profile: L2 | NIST: IA-4, IA-5
# https://howtoharden.com/guides/github/#43-enforce-fine-grained-personal-access-tokens
source "$(dirname "$0")/common.sh"

banner "4.08: Enforce Fine-Grained PATs"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.08 Managing fine-grained PAT policies for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-fine-grained-pats
# List active fine-grained PATs in the organization
info "4.08 Listing fine-grained personal access tokens..."
PATS=$(gh_get "/orgs/${GITHUB_ORG}/personal-access-tokens?per_page=100") || {
  warn "4.08 Unable to list PATs (requires org admin with fine_grained_pat scope)"
}

echo "${PATS}" | jq '.[] | {
  id: .id,
  owner: .owner.login,
  repository_selection: .repository_selection,
  permissions: .permissions,
  access_granted_at: .access_granted_at,
  token_expired: .token_expired,
  token_expires_at: .token_expires_at
}'

# List pending PAT requests
info "4.08 Listing pending PAT access requests..."
REQUESTS=$(gh_get "/orgs/${GITHUB_ORG}/personal-access-token-requests?per_page=100") || {
  warn "4.08 Unable to list PAT requests"
}
echo "${REQUESTS}" | jq '.[] | {id: .id, owner: .owner.login, reason: .reason}'
# HTH Guide Excerpt: end api-list-fine-grained-pats

# HTH Guide Excerpt: begin api-restrict-pat-policy
# Restrict PAT access to the organization (require approval)
info "4.08 Setting fine-grained PAT policy to require approval..."
gh_patch "/orgs/${GITHUB_ORG}" '{
  "personal_access_token_requests_enabled": true
}' || {
  warn "4.08 Unable to set PAT policy (may require enterprise admin)"
}
pass "4.08 Fine-grained PAT approval requirement configured"
# HTH Guide Excerpt: end api-restrict-pat-policy

increment_applied
summary
