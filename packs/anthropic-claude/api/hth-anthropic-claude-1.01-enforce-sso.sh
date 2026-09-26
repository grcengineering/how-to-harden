#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-claude-1.1
#   guide:   https://howtoharden.com/guides/anthropic-claude/#11-enforce-single-sign-on
#   profile: L1
#   mode:    read-only
#   requires: ANTHROPIC_ADMIN_KEY(Console Admin API key; Console admin keys have no selectable scopes)
# =============================================================================
# HTH Anthropic Claude Control 1.1: Enforce SSO (SAML/OIDC)
# Profile: L1 | NIST: IA-2, IA-8 | SOC 2: CC6.1
#
# Note: SSO is configured via the Claude Console UI (Settings > Identity & Access).
# There is no Admin API endpoint for SSO configuration.
# This script lists every organization member for an IdP cross-reference.
# Exit codes: 0 member list retrieved | 1 missing key or failed API call
source "$(dirname "$0")/common.sh"

banner "1.1: Enforce Single Sign-On (SAML/OIDC)"
require_admin_key

# HTH Guide Excerpt: begin api-validate-sso
# Validate SSO enforcement by listing org members and checking for
# users who may not have authenticated via SSO.
# Note: The Admin API does not expose SSO status directly.
# This audit lists all members so you can cross-reference with your IdP.
info "Listing all organization members for SSO cross-reference audit..."
MEMBERS=$(anthropic_list_all "/v1/organizations/users") || {
  fail "1.1 Failed to list organization users"
  summary; exit 1
}

MEMBER_COUNT=$(echo "${MEMBERS}" | jq 'length')
info "Found ${MEMBER_COUNT} organization members"

# Header row printed by hand: `column -N` is util-linux only (BSD/macOS rejects it)
{
  printf 'NAME\tEMAIL\tROLE\n'
  echo "${MEMBERS}" | jq -r '.[] | "\(.name)\t\(.email)\t\(.role)"'
} | column -t -s $'\t'

pass "1.1 Member list retrieved — cross-reference with IdP to verify SSO coverage"
# HTH Guide Excerpt: end api-validate-sso

summary
