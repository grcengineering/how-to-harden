#!/usr/bin/env bash
# HTH Auth0 Control 3.1: Restrict Dashboard Admin Access
# Profile: L1 | NIST: AC-6(1) | CIS: 5.4
# https://howtoharden.com/guides/auth0/#31-restrict-dashboard-admin-access
source "$(dirname "$0")/common.sh"

banner "3.1: Restrict Dashboard Admin Access"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "3.1 Auditing tenant settings..."

# HTH Guide Excerpt: begin api-harden-tenant
# Harden tenant session and security settings
info "3.1 Applying hardened tenant settings..."
RESPONSE=$(a0_patch "/tenants/settings" '{
  "session_lifetime": 8,
  "idle_session_lifetime": 1,
  "flags": {
    "disable_clickjack_protection_headers": false,
    "enable_public_signup_user_exists_error": false,
    "revoke_refresh_token_grant": true,
    "enable_sso": true
  },
  "session_cookie": { "mode": "non-persistent" }
}') || {
  fail "3.1 Failed to update tenant settings"
  increment_failed; summary; exit 0
}
# HTH Guide Excerpt: end api-harden-tenant

SESSION=$(echo "${RESPONSE}" | jq -r '.session_lifetime')
pass "3.1 Tenant session lifetime set to ${SESSION}h"
increment_applied
summary
