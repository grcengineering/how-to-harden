#!/usr/bin/env bash
# HTH LaunchDarkly Control 1.2: Role-Based Access Control
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/launchdarkly/#12-role-based-access-control
source "$(dirname "$0")/common.sh"

banner "1.2: Role-Based Access Control"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.2 Creating least-privilege custom roles..."

# HTH Guide Excerpt: begin api-create-custom-roles
# Create a production read-only custom role
EXISTING=$(ld_get "/roles" | jq -r '.items[].key') || true

if echo "${EXISTING}" | grep -q "^hth-prod-readonly$"; then
  info "1.2 Role 'hth-prod-readonly' already exists"
else
  info "1.2 Creating 'hth-prod-readonly' custom role..."
  RESPONSE=$(ld_post "/roles" '{
    "key": "hth-prod-readonly",
    "name": "HTH Production Read-Only",
    "description": "Read-only access to production environment",
    "basePermissions": "no_access",
    "policy": [
      {
        "effect": "allow",
        "actions": ["viewProject"],
        "resources": ["proj/*"]
      },
      {
        "effect": "deny",
        "actions": ["updateOn", "updateOff", "updateRules", "updateTargets", "updateFallthrough"],
        "resources": ["proj/*:env/production:flag/*"]
      }
    ]
  }') || {
    fail "1.2 Failed to create custom role"
    increment_failed; summary; exit 0
  }
  pass "1.2 Custom role 'hth-prod-readonly' created"
fi
# HTH Guide Excerpt: end api-create-custom-roles

# Audit members with admin role
info "1.2 Auditing admin role assignments..."
ADMINS=$(ld_get "/members?limit=100" | jq '[.items[] | select(.role == "admin")] | length')
info "1.2 Members with admin role: ${ADMINS}"
[ "${ADMINS}" -le 3 ] && { pass "1.2 Admin count within recommended threshold (≤3)"; increment_applied; } || { warn "1.2 Consider reducing admin count (currently ${ADMINS})"; increment_applied; }

summary
