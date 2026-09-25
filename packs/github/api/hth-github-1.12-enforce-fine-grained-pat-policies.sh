#!/usr/bin/env bash
# HTH GitHub Control 1.12: Enforce Fine-Grained PAT Policies
# Profile: L2 | NIST: AC-6, IA-4, IA-5
# https://howtoharden.com/guides/github/#17-enforce-fine-grained-personal-access-token-pat-policies
#
# The personal-access-token endpoints accept ONLY a GitHub App installation token
# (organization permission "Personal access tokens"); a PAT is rejected.
# Usage: bash <pack>              -> audit (list tokens and pending requests)
#        bash <pack> <pat_id>     -> also revoke that token
source "$(dirname "$0")/common.sh"

banner "1.12: Enforce Fine-Grained PAT Policies"
should_apply 2 || { increment_skipped; summary; exit 0; }

info "1.12 Auditing fine-grained PAT usage in ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-fine-grained-pats
# List all active fine-grained personal access tokens in the organization
gh api "/orgs/${GITHUB_ORG}/personal-access-tokens" \
  --paginate \
  --jq '.[] | {id, owner: .owner.login, token_name, token_expires_at, repository_selection}' || {
  fail "1.12 Unable to list fine-grained PATs (requires a GitHub App installation token)"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-list-fine-grained-pats

# HTH Guide Excerpt: begin api-list-pat-requests
# List pending fine-grained PAT requests awaiting approval
gh api "/orgs/${GITHUB_ORG}/personal-access-token-requests" \
  --paginate \
  --jq '.[] | {id, owner: .owner.login, token_name, token_expires_at, repository_selection}' || {
  fail "1.12 Unable to list PAT requests (requires a GitHub App installation token)"
  increment_failed
}
# HTH Guide Excerpt: end api-list-pat-requests

# HTH Guide Excerpt: begin api-revoke-pat
# Revoke a specific fine-grained PAT (pass its id from the listing above)
if [ -n "${1:-}" ]; then
  gh api --method POST "/orgs/${GITHUB_ORG}/personal-access-tokens/$1" -f action=revoke
fi
# HTH Guide Excerpt: end api-revoke-pat

increment_applied
summary
