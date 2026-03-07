#!/usr/bin/env bash
# HTH GitHub Control 1.12: Enforce Fine-Grained PAT Policies
# Profile: L2 | NIST: AC-6, IA-4, IA-5
# https://howtoharden.com/guides/github/#16-enforce-fine-grained-personal-access-token-policies
source "$(dirname "$0")/common.sh"

banner "1.12: Enforce Fine-Grained PAT Policies"
should_apply 2 || { increment_skipped; summary; exit 0; }

info "1.12 Auditing fine-grained PAT usage in ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-fine-grained-pats
# List all active fine-grained personal access tokens in the organization
gh api "/orgs/${GITHUB_ORG}/personal-access-tokens" \
  --paginate \
  --jq '.[] | {id, owner: .owner.login, expires_at, repositories_count: (.repositories | length), permissions: .permissions}'
# HTH Guide Excerpt: end api-list-fine-grained-pats

# HTH Guide Excerpt: begin api-list-pat-requests
# List pending fine-grained PAT requests awaiting approval
gh api "/orgs/${GITHUB_ORG}/personal-access-token-requests" \
  --jq '.[] | {id, owner: .owner.login, token_name: .token_name, repositories_count: (.repositories | length)}'
# HTH Guide Excerpt: end api-list-pat-requests

# HTH Guide Excerpt: begin api-revoke-pat
# Revoke a specific fine-grained PAT by ID (use for compromised or overprivileged tokens)
# Replace PAT_ID with the actual token ID from the listing above
PAT_ID="${1:?Usage: $0 <pat_id>}"
gh api --method DELETE "/orgs/${GITHUB_ORG}/personal-access-tokens/${PAT_ID}"
# HTH Guide Excerpt: end api-revoke-pat

increment_applied
summary
