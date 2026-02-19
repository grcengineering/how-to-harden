#!/usr/bin/env bash
# HTH GitHub Control 5.08: Apply GitHub-Recommended Security Configuration
# Profile: L1 | NIST: CM-6
# https://howtoharden.com/guides/github/#72-apply-github-recommended-security-configuration
source "$(dirname "$0")/common.sh"

banner "5.08: Apply Security Configuration"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.08 Checking security configurations for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-apply-security-config
# List available security configurations
info "5.08 Listing security configurations for ${GITHUB_ORG}..."
CONFIGS=$(gh_get "/orgs/${GITHUB_ORG}/code-security/configurations") || {
  fail "5.08 Unable to retrieve security configurations"
  increment_failed
  summary
  exit 0
}
echo "${CONFIGS}" | jq '.[] | {name: .name, id: .id, target_type: .target_type}'

# Apply configuration to all repositories
CONFIG_ID=$(echo "${CONFIGS}" | jq -r '.[0].id // empty')
if [ -n "${CONFIG_ID}" ]; then
  info "5.08 Applying configuration ${CONFIG_ID} to all repositories..."
  gh_post "/orgs/${GITHUB_ORG}/code-security/configurations/${CONFIG_ID}/attach" '{"scope": "all"}' || {
    fail "5.08 Failed to apply security configuration"
    increment_failed
    summary
    exit 0
  }
  pass "5.08 Security configuration applied to all repositories"
fi
# HTH Guide Excerpt: end api-apply-security-config

increment_applied
summary
