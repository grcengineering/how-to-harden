#!/usr/bin/env bash
# HTH Anthropic Claude Control 1.1: Enforce SSO (SAML/OIDC)
# Profile: L1 | NIST: IA-2, IA-8 | SOC 2: CC6.1
# https://howtoharden.com/guides/anthropic-claude/#11-enforce-single-sign-on
#
# Note: SSO is configured via the Claude Console UI (Settings > Identity & Access).
# There is no Admin API endpoint for SSO configuration.
# This script validates SSO is in effect by checking user authentication patterns.
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
  summary; exit 0
}

MEMBER_COUNT=$(echo "${MEMBERS}" | jq 'length')
info "Found ${MEMBER_COUNT} organization members"

echo "${MEMBERS}" | jq -r '.[] | "\(.name)\t\(.email)\t\(.role)"' | \
  column -t -s $'\t' -N "NAME,EMAIL,ROLE"

pass "1.1 Member list retrieved — cross-reference with IdP to verify SSO coverage"
# HTH Guide Excerpt: end api-validate-sso

summary
