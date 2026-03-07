#!/usr/bin/env bash
# HTH GitHub Control 3.19: Enable Code Security Configurations
# Profile: L1 | NIST: CM-2, CM-6, SA-11
# https://howtoharden.com/guides/github/#38-enable-organization-level-code-security-configurations
source "$(dirname "$0")/common.sh"

banner "3.19: Enable Code Security Configurations"
should_apply 1 || { increment_skipped; summary; exit 0; }

info "3.19 Checking code security configurations in ${GITHUB_ORG}..."

CONFIGS=$(gh_get "/orgs/${GITHUB_ORG}/code-security/configurations") || {
  fail "3.19 Unable to retrieve code security configurations"
  increment_failed
  summary
  exit 0
}

CONFIG_COUNT=$(echo "${CONFIGS}" | jq '. | length')

if [ "${CONFIG_COUNT}" -gt "0" ]; then
  pass "3.19 Code security configurations exist (${CONFIG_COUNT} found)"
  echo "${CONFIGS}" | jq '.[] | {id, name, target_type, attached_count}'
fi

# HTH Guide Excerpt: begin api-create-security-config
# Create a hardened code security configuration
gh api --method POST \
  "/orgs/${GITHUB_ORG}/code-security/configurations" \
  -f name="hth-hardened" \
  -f description="How To Harden security baseline configuration" \
  -f dependency_graph="enabled" \
  -f dependabot_alerts="enabled" \
  -f dependabot_security_updates="enabled" \
  -f secret_scanning="enabled" \
  -f secret_scanning_push_protection="enabled" \
  -f code_scanning_default_setup="enabled" \
  -f private_vulnerability_reporting="enabled"
# HTH Guide Excerpt: end api-create-security-config

# HTH Guide Excerpt: begin api-attach-security-config
# Attach a security configuration to all repositories in the organization
CONFIG_ID="${1:?Usage: $0 <config_id>}"
gh api --method POST \
  "/orgs/${GITHUB_ORG}/code-security/configurations/${CONFIG_ID}/attach" \
  -f scope="all"
# HTH Guide Excerpt: end api-attach-security-config

increment_applied
summary
