#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-claude-1.3
#   guide:   https://howtoharden.com/guides/anthropic-claude/#13-protect-admin-api-keys
#   profile: L1
#   mode:    read-only
#   requires: ANTHROPIC_ADMIN_KEY(the Console Admin API key under test)
# =============================================================================
# HTH Anthropic Claude Control 1.3: Protect Admin API Keys
# Profile: L1 | NIST: IA-5, SC-12 | SOC 2: CC6.1
# Exit codes: 0 key valid | 1 key missing, invalid, expired, or API unreachable
source "$(dirname "$0")/common.sh"

banner "1.3: Protect Admin API Keys"
require_admin_key

# HTH Guide Excerpt: begin api-audit-admin-keys
# Admin API keys (sk-ant-admin...) can only be created in the Console, and
# this script cannot list them. It proves the current admin key still works;
# a dead key exits 1, so a scheduler or CI gate sees the failure.
info "Validating admin key by retrieving organization info..."
ORG_INFO=$(anthropic_get "/v1/organizations/me") || {
  fail "1.3 Admin key is invalid or expired"
  summary; exit 1
}

ORG_NAME=$(echo "${ORG_INFO}" | jq -r '.name')
ORG_TYPE=$(echo "${ORG_INFO}" | jq -r '.type')
info "Organization: ${ORG_NAME} (type: ${ORG_TYPE})"
pass "1.3 Admin API key is valid and active"
# HTH Guide Excerpt: end api-audit-admin-keys

summary
