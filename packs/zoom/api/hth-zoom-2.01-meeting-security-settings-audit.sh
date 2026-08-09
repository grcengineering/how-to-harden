#!/usr/bin/env bash
# =============================================================================
# HTH Zoom Control 2.1: Enforce Meeting Password and Waiting Room
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 AC-3
# Source: https://howtoharden.com/guides/zoom/#21-enforce-meeting-password-and-waiting-room
# Interface: Zoom REST API v2 (Zoom has no first-party CLI)
#   GET /v2/accounts/{accountId}/settings       (scope: account:read:admin)
#   GET /v2/accounts/{accountId}/lock_settings  (scope: account:read:admin)
#   Verified against https://developers.zoom.us/docs/api/accounts/
# Auth: Server-to-Server OAuth app credentials —
#   https://developers.zoom.us/docs/internal-apps/s2s-oauth/
# Notes:
#   - accountId "me" targets the caller's own account.
#   - This is a VERIFICATION pack: it proves the passcode / waiting-room /
#     authentication posture and its account-level locks; the settings
#     themselves are enforced in the Admin console per the guide.
# =============================================================================

set -euo pipefail

: "${ZOOM_ACCOUNT_ID:?Set ZOOM_ACCOUNT_ID from the Server-to-Server OAuth app}"
: "${ZOOM_CLIENT_ID:?Set ZOOM_CLIENT_ID from the Server-to-Server OAuth app}"
: "${ZOOM_CLIENT_SECRET:?Set ZOOM_CLIENT_SECRET from the Server-to-Server OAuth app}"

# HTH Guide Excerpt: begin api-audit-meeting-security

# --- Mint a Server-to-Server OAuth access token (valid one hour) ---
ZOOM_TOKEN=$(curl -s -X POST "https://zoom.us/oauth/token" \
  -H "Authorization: Basic $(printf '%s:%s' "${ZOOM_CLIENT_ID}" "${ZOOM_CLIENT_SECRET}" | base64 | tr -d '\n')" \
  -d "grant_type=account_credentials" \
  -d "account_id=${ZOOM_ACCOUNT_ID}" | jq -r '.access_token')

# --- Audit: passcode, waiting-room, and authentication posture ---
# schedule_meeting / in_meeting / meeting_security are the documented
# account-settings groups that carry this control's toggles.
echo "=== Account settings: schedule_meeting, in_meeting, meeting_security ==="
curl -s -H "Authorization: Bearer ${ZOOM_TOKEN}" \
  "https://api.zoom.us/v2/accounts/me/settings" | \
  jq '{schedule_meeting, in_meeting, meeting_security}'

# --- Audit: are those settings LOCKED at the account level? ---
# An enabled-but-unlocked setting can be weakened by any group or host.
echo ""
echo "=== Account-level locked settings ==="
curl -s -H "Authorization: Bearer ${ZOOM_TOKEN}" \
  "https://api.zoom.us/v2/accounts/me/lock_settings" | jq '.'

# HTH Guide Excerpt: end api-audit-meeting-security
