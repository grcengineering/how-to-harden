#!/usr/bin/env bash
# HTH GitHub Control 7.02: Configure Copilot Governance
# Profile: L1 | NIST: AC-3, AU-2
# https://howtoharden.com/guides/github/#71-configure-copilot-governance
source "$(dirname "$0")/common.sh"

banner "7.02: Configure Copilot Governance"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "7.02 Configuring Copilot governance for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-copilot-get-settings
# Get current Copilot organization settings
info "7.02 Retrieving Copilot organization settings..."
SETTINGS=$(gh_get "/orgs/${GITHUB_ORG}/copilot/billing") || {
  warn "7.02 Unable to retrieve Copilot settings (requires manage_billing:copilot scope)"
}
echo "${SETTINGS}" | jq '{
  seat_breakdown: .seat_breakdown,
  public_code_suggestions: .public_code_suggestions,
  ide_chat: .ide_chat,
  platform_chat: .platform_chat,
  cli: .cli
}'
# HTH Guide Excerpt: end api-copilot-get-settings

# HTH Guide Excerpt: begin api-copilot-content-exclusions
# Get and set Copilot content exclusion rules
info "7.02 Retrieving Copilot content exclusion rules..."
EXCLUSIONS=$(gh_get "/orgs/${GITHUB_ORG}/copilot/content_exclusions") || {
  warn "7.02 Unable to retrieve content exclusions"
}
echo "${EXCLUSIONS}" | jq '.'

# Set content exclusion rules to protect sensitive paths
info "7.02 Setting Copilot content exclusion rules..."
gh_put "/orgs/${GITHUB_ORG}/copilot/content_exclusions" '[
  {
    "repository": "*",
    "paths": [
      "**/.env*",
      "**/secrets/**",
      "**/credentials/**",
      "**/*secret*",
      "**/*credential*",
      "**/*.pem",
      "**/*.key"
    ]
  }
]' || {
  warn "7.02 Unable to set content exclusion rules"
}
pass "7.02 Copilot content exclusion rules configured"
# HTH Guide Excerpt: end api-copilot-content-exclusions

# HTH Guide Excerpt: begin api-copilot-audit-usage
# Audit Copilot usage via the audit log
info "7.02 Querying Copilot audit events..."
gh_get "/orgs/${GITHUB_ORG}/audit-log?phrase=action:copilot&per_page=25" \
  | jq '.[] | {action: .action, actor: .actor, created_at: .created_at}' || {
  warn "7.02 Unable to query Copilot audit events"
}
# HTH Guide Excerpt: end api-copilot-audit-usage

increment_applied
summary
