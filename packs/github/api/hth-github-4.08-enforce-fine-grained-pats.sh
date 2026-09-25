#!/usr/bin/env bash
# HTH GitHub Control 4.08: Enforce Fine-Grained Personal Access Tokens (audit)
# Profile: L2 | NIST: IA-4, IA-5
# https://howtoharden.com/guides/github/#43-enforce-fine-grained-personal-access-tokens
#
# Requires a GitHub App installation token with the organization permission
# "Personal access tokens" (read); these endpoints reject personal access tokens.
# The organization PAT policy itself has no write API (ClickOps only).
source "$(dirname "$0")/common.sh"

banner "4.08: Enforce Fine-Grained PATs"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "4.08 Auditing fine-grained PATs for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-fine-grained-pats
# List active fine-grained PATs in the organization
info "4.08 Listing fine-grained personal access tokens..."
PATS=$(gh_get "/orgs/${GITHUB_ORG}/personal-access-tokens?per_page=100") || {
  fail "4.08 Unable to list PATs (requires a GitHub App installation token)"
  increment_failed
  summary
  exit 0
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
  fail "4.08 Unable to list PAT requests (requires a GitHub App installation token)"
  increment_failed
  summary
  exit 0
}
echo "${REQUESTS}" | jq '.[] | {id: .id, owner: .owner.login, reason: .reason}'
# HTH Guide Excerpt: end api-list-fine-grained-pats

increment_applied
summary
