#!/usr/bin/env bash
# HTH Anthropic Claude Control 6.1: Audit and Clean Up Pending Invites
# Profile: L1 | NIST: AC-2(3) | SOC 2: CC6.2
# https://howtoharden.com/guides/anthropic-claude/#61-audit-and-clean-up-pending-invites
source "$(dirname "$0")/common.sh"

banner "6.1: Audit and Clean Up Pending Invites"
require_admin_key

# HTH Guide Excerpt: begin api-audit-invites
# List all pending invites and identify stale ones
info "Listing all organization invites..."
INVITES=$(anthropic_list_all "/v1/organizations/invites") || {
  fail "6.1 Failed to list invites"
  summary; exit 0
}

TOTAL=$(echo "${INVITES}" | jq 'length')
PENDING=$(echo "${INVITES}" | jq '[.[] | select(.status == "pending")] | length')
EXPIRED=$(echo "${INVITES}" | jq '[.[] | select(.status == "expired")] | length')
ACCEPTED=$(echo "${INVITES}" | jq '[.[] | select(.status == "accepted")] | length')

info "Invites: total=${TOTAL}, pending=${PENDING}, expired=${EXPIRED}, accepted=${ACCEPTED}"

if [[ "${PENDING}" -gt 0 ]]; then
  warn "6.1 ${PENDING} pending invites found — review for stale or unauthorized invitations:"
  echo "${INVITES}" | jq -r '.[] | select(.status == "pending") |
    "  \(.email) | Role: \(.role) | Created: \(.created_at) | Expires: \(.expires_at)"'
else
  pass "6.1 No pending invites"
fi
# HTH Guide Excerpt: end api-audit-invites

# HTH Guide Excerpt: begin api-revoke-invite
# Revoke a specific pending invite
# Usage: Set INVITE_ID before running
if [[ -n "${INVITE_ID:-}" ]]; then
  info "Revoking invite ${INVITE_ID}..."
  anthropic_delete "/v1/organizations/invites/${INVITE_ID}" || {
    fail "6.1 Failed to revoke invite"
    summary; exit 0
  }
  pass "6.1 Invite ${INVITE_ID} revoked"
fi
# HTH Guide Excerpt: end api-revoke-invite

summary
