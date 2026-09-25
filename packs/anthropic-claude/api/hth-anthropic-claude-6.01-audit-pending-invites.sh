#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-claude-2.1
#   guide:   https://howtoharden.com/guides/anthropic-claude/#21-audit-and-clean-up-pending-invites
#   profile: L1
#   mode:    mutating
#   requires: ANTHROPIC_ADMIN_KEY(Console Admin API key; no selectable scopes), INVITE_ID(optional; arms the write)
# =============================================================================
# HTH Anthropic Claude Control 2.1: Audit and Clean Up Pending Invites
# (file keeps section 6.01 from the pre-split guide; it renders at hub control 2.1)
# Profile: L1 | NIST: AC-2(3) | SOC 2: CC6.2
#
# WHY `mode: mutating` DESPITE A READ-ONLY DEFAULT. With no arguments this is an
# invite audit (GET only). The api-revoke-invite region deletes an invite
# (DELETE /v1/organizations/invites/{id}) when INVITE_ID is set. The sync keeps
# one api/ pack per section, so the write cannot move to a separate file.
# Run with INVITE_ID unset for evidence collection.
# Exit codes: 0 audit (or revoke) completed | 1 missing key, bad input, or failed API call
source "$(dirname "$0")/common.sh"

banner "2.1: Audit and Clean Up Pending Invites"
require_admin_key

# HTH Guide Excerpt: begin api-audit-invites
# List all pending invites and identify stale ones
info "Listing all organization invites..."
INVITES=$(anthropic_list_all "/v1/organizations/invites") || {
  fail "2.1 Failed to list invites"
  summary; exit 1
}

TOTAL=$(echo "${INVITES}" | jq 'length')
PENDING=$(echo "${INVITES}" | jq '[.[] | select(.status == "pending")] | length')
EXPIRED=$(echo "${INVITES}" | jq '[.[] | select(.status == "expired")] | length')
ACCEPTED=$(echo "${INVITES}" | jq '[.[] | select(.status == "accepted")] | length')

info "Invites: total=${TOTAL}, pending=${PENDING}, expired=${EXPIRED}, accepted=${ACCEPTED}"

if [[ "${PENDING}" -gt 0 ]]; then
  warn "2.1 ${PENDING} pending invites found — review for stale or unauthorized invitations:"
  echo "${INVITES}" | jq -r '.[] | select(.status == "pending") |
    "  \(.email) | Role: \(.role) | Invited: \(.invited_at) | Expires: \(.expires_at)"'
else
  pass "2.1 No pending invites"
fi
# HTH Guide Excerpt: end api-audit-invites

# HTH Guide Excerpt: begin api-revoke-invite
# WRITE: revoke one pending invite. Runs only when INVITE_ID is set.
if [[ -n "${INVITE_ID:-}" ]]; then
  [[ "${INVITE_ID}" =~ ^[A-Za-z0-9_-]+$ ]] || { fail "2.1 INVITE_ID is not a valid invite id"; summary; exit 1; }
  info "Revoking invite ${INVITE_ID}..."
  anthropic_delete "/v1/organizations/invites/${INVITE_ID}" || {
    fail "2.1 Failed to revoke invite"
    summary; exit 1
  }
  pass "2.1 Invite ${INVITE_ID} revoked"
fi
# HTH Guide Excerpt: end api-revoke-invite

summary
