#!/usr/bin/env bash
# HTH HashiCorp Vault Control 1.1: Implement Least-Privilege Auth Methods
# Profile: L1 | NIST: IA-2, IA-5, AC-2 | SOC 2: CC6.1, CC6.2
# https://howtoharden.com/guides/hashicorp-vault/#11-implement-least-privilege-auth-methods
source "$(dirname "$0")/common.sh"

banner "1.1: Implement Least-Privilege Auth Methods"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Auditing authentication methods..."

# HTH Guide Excerpt: begin api-configure-auth
# Check for root token usage (critical finding)
info "1.1 Checking for root token usage..."
TOKEN_INFO=$(vault_get "/auth/token/lookup-self" 2>/dev/null || echo '{}')
TOKEN_POLICIES=$(echo "${TOKEN_INFO}" | jq -r '.data.policies // [] | join(",")' 2>/dev/null || echo "")

if echo "${TOKEN_POLICIES}" | grep -q "root"; then
  fail "1.1 CRITICAL: Current token has root policy -- rotate to a scoped admin token immediately"
  warn "1.1 Root tokens should only be used for break-glass emergency procedures"
  increment_failed
else
  pass "1.1 Current token does not use root policy"
fi

# List all enabled auth methods
info "1.1 Listing enabled auth methods..."
AUTH_METHODS=$(vault_get "/sys/auth" 2>/dev/null || echo '{}')
AUTH_PATHS=$(echo "${AUTH_METHODS}" | jq -r '.data // . | to_entries[] | select(.value.type?) | "\(.key) (\(.value.type))"' 2>/dev/null || true)

if [ -n "${AUTH_PATHS}" ]; then
  pass "1.1 Enabled auth methods:"
  echo "${AUTH_PATHS}" | while read -r line; do
    echo "  - ${line}"
  done
else
  fail "1.1 Could not retrieve auth methods -- check token permissions"
  increment_failed
fi

# Verify OIDC is configured (preferred for human users)
info "1.1 Checking for OIDC auth method..."
OIDC_ENABLED=$(echo "${AUTH_METHODS}" | jq -r '.data // . | to_entries[] | select(.value.type == "oidc") | .key' 2>/dev/null || true)

if [ -n "${OIDC_ENABLED}" ]; then
  pass "1.1 OIDC auth method enabled at path: ${OIDC_ENABLED}"

  # Verify OIDC configuration is complete
  OIDC_CONFIG=$(vault_get "/auth/oidc/config" 2>/dev/null || echo '{}')
  OIDC_DISCOVERY=$(echo "${OIDC_CONFIG}" | jq -r '.data.oidc_discovery_url // empty' 2>/dev/null || true)

  if [ -n "${OIDC_DISCOVERY}" ]; then
    pass "1.1 OIDC discovery URL configured: ${OIDC_DISCOVERY}"
  else
    warn "1.1 OIDC auth method enabled but discovery URL not configured"
  fi
else
  warn "1.1 OIDC auth method not enabled -- recommended for human user authentication"
  warn "1.1 Enable with: vault auth enable oidc"
fi

# Check for deprecated or insecure auth methods
info "1.1 Checking for deprecated auth methods..."
USERPASS_ENABLED=$(echo "${AUTH_METHODS}" | jq -r '.data // . | to_entries[] | select(.value.type == "userpass") | .key' 2>/dev/null || true)

if [ -n "${USERPASS_ENABLED}" ]; then
  warn "1.1 Userpass auth method detected at: ${USERPASS_ENABLED}"
  warn "1.1 Consider migrating to OIDC for stronger authentication guarantees"
fi
# HTH Guide Excerpt: end api-configure-auth

increment_applied

summary
