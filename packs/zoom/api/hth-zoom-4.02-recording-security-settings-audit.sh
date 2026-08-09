#!/usr/bin/env bash
# =============================================================================
# HTH Zoom Control 4.2: Configure Recording Security
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 SC-28
# Source: https://howtoharden.com/guides/zoom/#42-configure-recording-security
# Interface: Zoom REST API v2 (Zoom has no first-party CLI)
#   GET /v2/accounts/{accountId}/settings       (scope: account:read:admin)
#   GET /v2/accounts/{accountId}/lock_settings  (scope: account:read:admin)
#   Verified against https://developers.zoom.us/docs/api/accounts/
# Auth: Server-to-Server OAuth app credentials —
#   https://developers.zoom.us/docs/internal-apps/s2s-oauth/
# Notes:
#   - accountId "me" targets the caller's own account.
#   - VERIFICATION pack: proves the recording protection posture (consent,
#     passcode protection, download/viewer restrictions) and whether the
#     recording settings are locked account-wide.
# =============================================================================

set -euo pipefail

: "${ZOOM_ACCOUNT_ID:?Set ZOOM_ACCOUNT_ID from the Server-to-Server OAuth app}"
: "${ZOOM_CLIENT_ID:?Set ZOOM_CLIENT_ID from the Server-to-Server OAuth app}"
: "${ZOOM_CLIENT_SECRET:?Set ZOOM_CLIENT_SECRET from the Server-to-Server OAuth app}"

# HTH Guide Excerpt: begin api-audit-recording-security

# --- Mint a Server-to-Server OAuth access token (valid one hour) ---
ZOOM_TOKEN=$(curl -s -X POST "https://zoom.us/oauth/token" \
  -H "Authorization: Basic $(printf '%s:%s' "${ZOOM_CLIENT_ID}" "${ZOOM_CLIENT_SECRET}" | base64 | tr -d '\n')" \
  -d "grant_type=account_credentials" \
  -d "account_id=${ZOOM_ACCOUNT_ID}" | jq -r '.access_token')

# --- Audit: the account's recording settings group ---
# "recording" is the documented account-settings group carrying cloud
# recording, consent, and access-protection toggles. Review every value
# against the guide's required posture.
echo "=== Account settings: recording ==="
curl -s -H "Authorization: Bearer ${ZOOM_TOKEN}" \
  "https://api.zoom.us/v2/accounts/me/settings" | \
  jq '.recording'

# --- Audit: is the recording configuration locked account-wide? ---
echo ""
echo "=== Account-level locks covering recording ==="
curl -s -H "Authorization: Bearer ${ZOOM_TOKEN}" \
  "https://api.zoom.us/v2/accounts/me/lock_settings" | \
  jq 'if has("recording") then {recording} else . end'

# HTH Guide Excerpt: end api-audit-recording-security
