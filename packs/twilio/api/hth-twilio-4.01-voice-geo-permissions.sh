#!/usr/bin/env bash
# =============================================================================
# HTH Twilio Control 4.1: Restrict Voice Dialing Geographic Permissions
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 4.8, 13.4 | NIST 800-53 AC-3, AC-4, SC-7
# Source: https://howtoharden.com/guides/twilio/#41-restrict-voice-dialing-geographic-permissions
# Interface: Twilio Voice v1 REST API
#   https://www.twilio.com/docs/voice/api/dialingpermissions-country-resource
#   https://www.twilio.com/docs/voice/api/dialingpermissions-settings-resource
# Auth: HTTP Basic (TWILIO_ACCOUNT_SID:TWILIO_AUTH_TOKEN)
# =============================================================================

set -euo pipefail

: "${TWILIO_ACCOUNT_SID:?Set TWILIO_ACCOUNT_SID}"
: "${TWILIO_AUTH_TOKEN:?Set TWILIO_AUTH_TOKEN}"

# HTH Guide Excerpt: begin api-audit-dialing-permissions

# --- Audit: which countries can this account currently dial? ---
# Countries returned with LowRiskNumbersEnabled=true are dialable today.
# Compare this list against the countries your business actually calls.
echo "=== Countries with low-risk dialing ENABLED ==="
curl -s -X GET "https://voice.twilio.com/v1/DialingPermissions/Countries?LowRiskNumbersEnabled=true&PageSize=1000" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}"

# --- Audit: any country where high-risk toll-fraud ranges are enabled? ---
# These are the number ranges International Revenue Share Fraud monetizes.
# This list should normally be EMPTY — every entry needs a documented reason.
echo ""
echo "=== Countries with HIGH-RISK toll-fraud ranges ENABLED (expect none) ==="
curl -s -X GET "https://voice.twilio.com/v1/DialingPermissions/Countries?HighRiskTollfraudNumbersEnabled=true&PageSize=1000" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}"

echo ""
echo "=== Countries with HIGH-RISK special-number ranges ENABLED (expect none) ==="
curl -s -X GET "https://voice.twilio.com/v1/DialingPermissions/Countries?HighRiskSpecialNumbersEnabled=true&PageSize=1000" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}"

# --- Drill into a single country's permission state ---
echo ""
echo "=== Permission detail for one country (example: US) ==="
curl -s -X GET "https://voice.twilio.com/v1/DialingPermissions/Countries/US" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}"

# HTH Guide Excerpt: end api-audit-dialing-permissions

# HTH Guide Excerpt: begin api-subaccount-inheritance

# --- Audit: do subaccounts inherit the parent account's dialing permissions? ---
echo "=== Current dialing-permissions inheritance setting ==="
curl -s -X GET "https://voice.twilio.com/v1/Settings" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}"

# --- Enforce: make subaccounts inherit the parent's dial plan ---
# With inheritance on, a subaccount cannot quietly widen its own dial plan.
curl -s -X POST "https://voice.twilio.com/v1/Settings" \
  --data-urlencode "DialingPermissionsInheritance=true" \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}"

# HTH Guide Excerpt: end api-subaccount-inheritance
