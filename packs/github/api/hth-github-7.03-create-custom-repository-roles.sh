#!/usr/bin/env bash
# HTH GitHub Control 7.03: Create Custom Repository Roles
# Profile: L2 | NIST: AC-2, AC-3
# https://howtoharden.com/guides/github/#72-create-custom-repository-roles
source "$(dirname "$0")/common.sh"

banner "7.03: Create Custom Repository Roles"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "7.03 Managing custom repository roles for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-custom-roles
# List existing custom repository roles
info "7.03 Listing custom repository roles..."
ROLES=$(gh_get "/orgs/${GITHUB_ORG}/custom-repository-roles") || {
  warn "7.03 Unable to list custom roles (requires Enterprise Cloud)"
}
echo "${ROLES}" | jq '.custom_roles[] | {id: .id, name: .name, base_role: .base_role, permissions: .permissions}'
# HTH Guide Excerpt: end api-list-custom-roles

# HTH Guide Excerpt: begin api-create-security-reviewer-role
# Create a Security Reviewer custom role
info "7.03 Creating Security Reviewer custom role..."
RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/custom-repository-roles" '{
  "name": "Security Reviewer",
  "description": "Can view security alerts and manage security settings",
  "base_role": "read",
  "permissions": [
    "security_events",
    "view_secret_scanning_alerts",
    "dismiss_secret_scanning_alerts",
    "view_dependabot_alerts",
    "dismiss_dependabot_alerts",
    "view_code_scanning_alerts",
    "dismiss_code_scanning_alerts"
  ]
}') || {
  warn "7.03 Unable to create custom role (may already exist)"
}
pass "7.03 Security Reviewer role created"
# HTH Guide Excerpt: end api-create-security-reviewer-role

increment_applied
summary
