#!/usr/bin/env bash
# HTH GitHub Control 7.03: Create Custom Repository Roles
# Profile: L2 | NIST: AC-2, AC-3
# https://howtoharden.com/guides/github/#72-create-custom-repository-roles
#
# Fine-grained permission names are defined by GitHub and discovered at run time
# from GET /orgs/{org}/repository-fine-grained-permissions -- never hardcoded.
# Usage: bash <pack>                                  -> list roles and the security permissions available
#        ROLE_PERMISSIONS="name1,name2,..." bash <pack> -> create the "Security Reviewer" role with them
source "$(dirname "$0")/common.sh"

banner "7.03: Create Custom Repository Roles"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "7.03 Managing custom repository roles for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-custom-roles
# List existing custom repository roles
info "7.03 Listing custom repository roles..."
ROLES=$(gh_get "/orgs/${GITHUB_ORG}/custom-repository-roles") || {
  fail "7.03 Unable to list custom roles (requires Enterprise Cloud)"
  increment_failed
  summary
  exit 0
}
echo "${ROLES}" | jq '.custom_roles[] | {id: .id, name: .name, base_role: .base_role, permissions: .permissions}'
# HTH Guide Excerpt: end api-list-custom-roles

# HTH Guide Excerpt: begin api-create-security-reviewer-role
# The fine-grained permissions GitHub offers for custom repository roles
AVAILABLE=$(gh_get "/orgs/${GITHUB_ORG}/repository-fine-grained-permissions" | jq -r '.[].name')
echo "Security-related permissions available:"
echo "${AVAILABLE}" | grep -iE 'alert|scanning|dependabot|secret|security|advisor' || true

# Create a Security Reviewer role from permissions you choose (validated against the list)
if [ -n "${ROLE_PERMISSIONS:-}" ]; then
  PERMS=$(printf '%s' "${ROLE_PERMISSIONS}" | tr ',' '\n' | sed '/^$/d')
  UNKNOWN=$(printf '%s\n' "${PERMS}" | grep -vxF -f <(echo "${AVAILABLE}") || true)
  if [ -n "${UNKNOWN}" ]; then
    fail "7.03 Not GitHub fine-grained permissions: $(echo "${UNKNOWN}" | tr '\n' ' ')"
    increment_failed
    summary
    exit 0
  fi
  BODY=$(printf '%s\n' "${PERMS}" | jq -R . | jq -s '{
    name: "Security Reviewer",
    description: "Can view and triage security alerts",
    base_role: "read",
    permissions: .
  }')
  gh_post "/orgs/${GITHUB_ORG}/custom-repository-roles" "${BODY}" >/dev/null || {
    fail "7.03 Unable to create custom role (may already exist)"
    increment_failed
    summary
    exit 0
  }
  pass "7.03 Security Reviewer role created"
fi
# HTH Guide Excerpt: end api-create-security-reviewer-role

increment_applied
summary
