#!/usr/bin/env bash
# HTH GitHub Control 5.05: Protect Deployment Environments
# Profile: L2 | NIST: CM-3, CM-5, SA-10
# https://howtoharden.com/guides/github/#55-protect-deployment-environments
source "$(dirname "$0")/common.sh"

banner "5.05: Protect Deployment Environments"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "5.05 Checking deployment environment protections on ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-audit-environments
# Audit: Check all deployment environments for protection rules
ENVS_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/environments") || {
  warn "5.05 Unable to retrieve environments (may not exist or require admin access)"
  increment_applied
  summary
  exit 0
}

ENVS=$(echo "${ENVS_DATA}" | jq -r '.environments // []')
ENV_COUNT=$(echo "${ENVS}" | jq '. | length' 2>/dev/null || echo "0")

info "5.05 Found ${ENV_COUNT} deployment environment(s)"

if [ "${ENV_COUNT}" = "0" ]; then
  pass "5.05 No deployment environments configured (nothing to protect)"
  increment_applied
  summary
  exit 0
fi

UNPROTECTED=0
for ENV_NAME in $(echo "${ENVS}" | jq -r '.[].name' 2>/dev/null); do
  RULES_COUNT=$(echo "${ENVS}" | jq "[.[] | select(.name == \"${ENV_NAME}\") | .protection_rules // [] | length] | add // 0" 2>/dev/null || echo "0")
  if [ "${RULES_COUNT}" = "0" ]; then
    warn "5.05 Environment '${ENV_NAME}' has no protection rules"
    UNPROTECTED=$((UNPROTECTED + 1))
  else
    pass "5.05 Environment '${ENV_NAME}' has ${RULES_COUNT} protection rule(s)"
  fi
done
# HTH Guide Excerpt: end api-audit-environments

if [ "${UNPROTECTED}" = "0" ]; then
  pass "5.05 All deployment environments have protection rules"
  increment_applied
  summary
  exit 0
fi

warn "5.05 ${UNPROTECTED} environment(s) lack protection rules"

# HTH Guide Excerpt: begin api-protect-environments
# Add protection rules to unprotected deployment environments
for ENV_NAME in $(echo "${ENVS}" | jq -r '.[].name' 2>/dev/null); do
  RULES_COUNT=$(echo "${ENVS}" | jq "[.[] | select(.name == \"${ENV_NAME}\") | .protection_rules // [] | length] | add // 0" 2>/dev/null || echo "0")
  if [ "${RULES_COUNT}" = "0" ]; then
    info "5.05 Adding protection rules to environment '${ENV_NAME}'..."
    gh_put "/repos/${GITHUB_ORG}/${REPO}/environments/${ENV_NAME}" '{
      "deployment_branch_policy": {
        "protected_branches": true,
        "custom_branch_policies": false
      }
    }' > /dev/null 2>&1 && {
      pass "5.05 Protection added to environment '${ENV_NAME}'"
    } || {
      warn "5.05 Failed to add protection to environment '${ENV_NAME}'"
    }
  fi
done
# HTH Guide Excerpt: end api-protect-environments

increment_applied
summary
