#!/usr/bin/env bash
# HTH LaunchDarkly Control 2.2: API Token Security
# Profile: L1 | NIST: IA-5
# https://howtoharden.com/guides/launchdarkly/#22-api-token-security
source "$(dirname "$0")/common.sh"

banner "2.2: API Token Security"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.2 Auditing API access tokens..."

# HTH Guide Excerpt: begin api-audit-tokens
# List all tokens and check for overly permissive ones
TOKENS=$(ld_get "/tokens?showAll=true") || {
  fail "2.2 Unable to retrieve access tokens"
  increment_failed; summary; exit 0
}

TOTAL_TOKENS=$(echo "${TOKENS}" | jq '.items | length')
ADMIN_TOKENS=$(echo "${TOKENS}" | jq '[.items[] | select(.role == "admin")] | length')
NO_ROLE_TOKENS=$(echo "${TOKENS}" | jq '[.items[] | select(.role == "writer" or .role == "admin") | select(.serviceToken == true)] | length')

info "2.2 Total tokens: ${TOTAL_TOKENS}"
info "2.2 Admin-level tokens: ${ADMIN_TOKENS}"
info "2.2 Service tokens with write/admin: ${NO_ROLE_TOKENS}"

if [ "${ADMIN_TOKENS}" -gt 0 ]; then
  warn "2.2 Tokens with admin role (should use scoped roles instead):"
  echo "${TOKENS}" | jq -r '.items[] | select(.role == "admin") | "  - \(.name // "unnamed") (id: \(._id))"'
  fail "2.2 ${ADMIN_TOKENS} token(s) have admin role — scope down with custom roles"
  increment_failed
else
  pass "2.2 No tokens with admin role"
  increment_applied
fi
# HTH Guide Excerpt: end api-audit-tokens

summary
