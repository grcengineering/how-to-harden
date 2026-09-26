#!/usr/bin/env bash
# HTH GitHub Control 8.03: Apply GitHub-Recommended Security Configuration
# Profile: L1 | NIST: CM-6
# https://howtoharden.com/guides/github/#83-apply-github-recommended-security-configuration
source "$(dirname "$0")/common.sh"

banner "8.03: Apply Security Configuration"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "8.03 Checking security configurations for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-apply-security-config
# Find the "GitHub recommended" configuration (a global configuration)
CONFIGS=$(gh_get "/orgs/${GITHUB_ORG}/code-security/configurations?target_type=global") || {
  fail "8.03 Unable to retrieve security configurations"
  increment_failed
  summary
  exit 0
}
echo "${CONFIGS}" | jq '.[] | {name: .name, id: .id, target_type: .target_type}'
CONFIG_ID=$(echo "${CONFIGS}" | jq -r '.[] | select(.name == "GitHub recommended") | .id')

# Attach it to every repository that has no configuration yet
if [ -n "${CONFIG_ID}" ]; then
  info "8.03 Applying GitHub recommended (${CONFIG_ID}) to repositories without a configuration..."
  gh_post "/orgs/${GITHUB_ORG}/code-security/configurations/${CONFIG_ID}/attach" \
    '{"scope": "all_without_configurations"}' >/dev/null || {
    fail "8.03 Failed to apply security configuration"
    increment_failed
    summary
    exit 0
  }
  pass "8.03 GitHub recommended configuration applied"
else
  fail "8.03 'GitHub recommended' configuration not found"
  increment_failed
  summary
  exit 0
fi
# HTH Guide Excerpt: end api-apply-security-config

increment_applied
summary
