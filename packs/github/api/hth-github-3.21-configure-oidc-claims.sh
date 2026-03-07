#!/usr/bin/env bash
# HTH GitHub Control 3.21: Harden Actions OIDC Subject Claims
# Profile: L2 | NIST: IA-2, IA-8
# https://howtoharden.com/guides/github/#36-harden-actions-oidc-claims
source "$(dirname "$0")/common.sh"

banner "3.21: Harden Actions OIDC Claims"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.21 Checking OIDC subject claim customization for ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- get current OIDC customization
CURRENT=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/actions/oidc/customization/sub") || {
  warn "3.21 Unable to retrieve OIDC customization (may not be configured)"
}

if [ -n "${CURRENT}" ]; then
  CLAIMS=$(echo "${CURRENT}" | jq -r '.include_claim_keys // [] | join(", ")')
  if [ -n "${CLAIMS}" ] && [ "${CLAIMS}" != "" ]; then
    pass "3.21 OIDC subject claim already customized with: ${CLAIMS}"
    increment_applied
    summary
    exit 0
  fi
fi

# HTH Guide Excerpt: begin api-customize-oidc-claims
# Customize OIDC subject claims to include repository, environment, and job_workflow_ref
# This restricts which workflows can assume cloud roles
info "3.21 Customizing OIDC subject claims for ${GITHUB_ORG}/${REPO}..."
RESPONSE=$(gh_put "/repos/${GITHUB_ORG}/${REPO}/actions/oidc/customization/sub" '{
  "use_default": false,
  "include_claim_keys": [
    "repo",
    "context",
    "job_workflow_ref"
  ]
}') || {
  fail "3.21 Failed to customize OIDC claims"
  increment_failed
  summary
  exit 0
}

# Verify the customization
info "3.21 Current OIDC subject claim template:"
gh_get "/repos/${GITHUB_ORG}/${REPO}/actions/oidc/customization/sub" \
  | jq '.'

# Set organization-level OIDC defaults
info "3.21 Setting organization OIDC subject claim template..."
gh_put "/orgs/${GITHUB_ORG}/actions/oidc/customization/sub" '{
  "include_claim_keys": [
    "repo",
    "context",
    "job_workflow_ref"
  ]
}'
# HTH Guide Excerpt: end api-customize-oidc-claims

pass "3.21 OIDC subject claims customized"
increment_applied

summary
