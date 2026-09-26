#!/usr/bin/env bash
# HTH Okta Control 1.2: Implement Admin Role Separation
# Profile: L1 | NIST: AC-5, AC-6(1)
# https://howtoharden.com/guides/okta/#12-implement-admin-role-separation
#
# Creating a custom admin role needs a token owned by a Super Administrator.
# A custom role grants nothing until it is assigned together with a resource set
# (Security > Administrators > Add administrator, or /api/v1/iam/resource-sets).
source "$(dirname "$0")/common.sh"

banner "1.2: Implement Admin Role Separation"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.2 Implementing admin role separation..."

# Check if Help Desk Admin role already exists (idempotent; a failed read stops the pack)
EXISTING=$(okta_get "/api/v1/iam/roles" \
  | jq -r '.roles[]? | select(.label == "Help Desk Admin") | .id')

if [ -n "${EXISTING}" ]; then
  pass "1.2 Help Desk Admin role already exists (ID: ${EXISTING})"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-create-role
# Create custom Help Desk Admin role
info "1.2 Creating Help Desk Admin custom role..."
if okta_post "/api/v1/iam/roles" '{
  "label": "Help Desk Admin",
  "description": "Limited admin for password resets and account unlocks",
  "permissions": [
    "okta.users.read",
    "okta.users.credentials.resetPassword",
    "okta.users.lifecycle.unlock"
  ]
}' > /dev/null; then
  pass "1.2 Help Desk Admin role created"
  increment_applied
else
  fail "1.2 Failed to create Help Desk Admin role"
  increment_failed
fi
# HTH Guide Excerpt: end api-create-role

summary
