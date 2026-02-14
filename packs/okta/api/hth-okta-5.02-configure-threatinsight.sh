#!/usr/bin/env bash
# HTH Okta Control 5.2: Configure ThreatInsight
# Profile: L1
# https://howtoharden.com/guides/okta/#52-configure-threatinsight
source "$(dirname "$0")/common.sh"

banner "5.2: Configure ThreatInsight"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.2 Configuring ThreatInsight..."

# Check current ThreatInsight settings
THREAT_CONFIG=$(okta_get "/api/v1/threats/configuration" 2>/dev/null || echo "{}")
CURRENT_ACTION=$(echo "${THREAT_CONFIG}" | jq -r '.action // "unknown"' 2>/dev/null || echo "unknown")

info "5.2 Current ThreatInsight action: ${CURRENT_ACTION}"

if [ "${CURRENT_ACTION}" = "block" ]; then
  pass "5.2 ThreatInsight already set to block"
  increment_applied
  summary
  exit 0
fi

# Enable ThreatInsight with block action
info "5.2 Setting ThreatInsight to block mode..."
okta_post "/api/v1/threats/configuration" '{
  "action": "block"
}' > /dev/null 2>&1 && {
  pass "5.2 ThreatInsight set to block mode"
  increment_applied
  summary
  exit 0
} || true

# Try PUT instead (API may vary by Okta version)
okta_put "/api/v1/threats/configuration" '{
  "action": "block"
}' > /dev/null 2>&1 && {
  pass "5.2 ThreatInsight set to block mode"
  increment_applied
} || {
  warn "5.2 Failed to configure ThreatInsight -- may require Adaptive MFA license"
  warn "5.2 Configure manually: Security > General > ThreatInsight > Block"
  increment_skipped
}

summary
