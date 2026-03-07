#!/usr/bin/env bash
# HTH GitHub Control 4.07: Audit GitHub App Installations and Permissions
# Profile: L1 | NIST: AC-6, CM-8
# https://howtoharden.com/guides/github/#42-audit-github-app-installations
source "$(dirname "$0")/common.sh"

banner "4.07: Audit GitHub App Installations"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.07 Auditing GitHub App installations for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-audit-github-apps
# List all GitHub App installations in the organization
info "4.07 Listing GitHub App installations..."
INSTALLATIONS=$(gh_get "/orgs/${GITHUB_ORG}/installations") || {
  fail "4.07 Unable to retrieve installations (requires org admin)"
  increment_failed
  summary
  exit 0
}

echo "${INSTALLATIONS}" | jq '.installations[] | {
  app_slug: .app_slug,
  app_id: .app_id,
  target_type: .target_type,
  repository_selection: .repository_selection,
  permissions: .permissions,
  created_at: .created_at,
  updated_at: .updated_at
}'

# Flag apps with excessive permissions
echo "${INSTALLATIONS}" | jq -r '.installations[] |
  select(.permissions.administration == "write" or
         .permissions.members == "write" or
         .permissions.organization_administration == "write") |
  "REVIEW: \(.app_slug) has elevated permissions: \(.permissions | keys | join(", "))"'
# HTH Guide Excerpt: end api-audit-github-apps

APP_COUNT=$(echo "${INSTALLATIONS}" | jq '.installations | length' 2>/dev/null || echo "0")
info "4.07 Found ${APP_COUNT} installed GitHub Apps"

increment_applied
summary
