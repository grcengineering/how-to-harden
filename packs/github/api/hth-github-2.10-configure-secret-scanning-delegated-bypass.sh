#!/usr/bin/env bash
# HTH GitHub Control 2.10: Configure Secret Scanning Delegated Bypass
# Profile: L2 | NIST: AC-3, AC-6, IA-5(7)
# https://howtoharden.com/guides/github/#26-configure-secret-scanning-delegated-bypass
source "$(dirname "$0")/common.sh"

banner "2.10: Configure Secret Scanning Delegated Bypass"
should_apply 2 || { increment_skipped; summary; exit 0; }

info "2.10 Checking code security configurations for delegated bypass in ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-security-configs
# List existing code security configurations to find those with delegated bypass
gh api "/orgs/${GITHUB_ORG}/code-security/configurations" \
  --jq '.[] | {id, name, secret_scanning_delegated_bypass}'
# HTH Guide Excerpt: end api-list-security-configs

# HTH Guide Excerpt: begin api-update-delegated-bypass
# Update a code security configuration to enable delegated bypass
# Replace CONFIG_ID with actual configuration ID and TEAM_ID with security team ID
CONFIG_ID="${1:?Usage: $0 <config_id> <security_team_id>}"
TEAM_ID="${2:?Usage: $0 <config_id> <security_team_id>}"

gh api --method PATCH \
  "/orgs/${GITHUB_ORG}/code-security/configurations/${CONFIG_ID}" \
  -f secret_scanning_delegated_bypass="enabled" \
  -f 'secret_scanning_delegated_bypass_options[reviewers][][reviewer_id]='"${TEAM_ID}" \
  -f 'secret_scanning_delegated_bypass_options[reviewers][][reviewer_type]=TEAM'
# HTH Guide Excerpt: end api-update-delegated-bypass

increment_applied
summary
