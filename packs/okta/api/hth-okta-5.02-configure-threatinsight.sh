#!/usr/bin/env bash
# HTH Okta Control 5.2: Configure ThreatInsight
# Profile: L1
# https://howtoharden.com/guides/okta/#52-configure-threatinsight
#
# GET/POST /api/v1/threats/configuration (Okta Management API, ThreatInsight).
# action "block" = console "Log and enforce security based on threat level";
# "audit" = log only; "none" = off. excludeZones (exempt network zones) is kept.
source "$(dirname "$0")/common.sh"

banner "5.2: Configure ThreatInsight"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.2 Configuring ThreatInsight..."

# Check current ThreatInsight settings (a failed read stops the pack)
THREAT_CONFIG=$(okta_get "/api/v1/threats/configuration")
CURRENT_ACTION=$(printf '%s' "${THREAT_CONFIG}" | jq -r '.action')

info "5.2 Current ThreatInsight action: ${CURRENT_ACTION}"

if [ "${CURRENT_ACTION}" = "block" ]; then
  pass "5.2 ThreatInsight already set to block (log and enforce)"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-update-threatinsight
# Set ThreatInsight to block, keeping any exempt zones already configured
info "5.2 Setting ThreatInsight to block mode..."
NEW_CONFIG=$(printf '%s' "${THREAT_CONFIG}" | jq '{action: "block", excludeZones: (.excludeZones // [])}')
if okta_post "/api/v1/threats/configuration" "${NEW_CONFIG}" > /dev/null; then
  pass "5.2 ThreatInsight set to block mode"
  increment_applied
else
  fail "5.2 Failed to configure ThreatInsight"
  increment_failed
fi
# HTH Guide Excerpt: end api-update-threatinsight

summary
