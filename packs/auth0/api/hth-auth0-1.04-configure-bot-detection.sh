#!/usr/bin/env bash
# HTH Auth0 Control 1.4: Configure Bot Detection
# Profile: L2 | NIST: SI-4 | CIS: 4.10
# https://howtoharden.com/guides/auth0/#14-configure-bot-detection
source "$(dirname "$0")/common.sh"

banner "1.4: Configure Bot Detection"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "1.4 Checking bot detection settings..."

CURRENT=$(a0_get "/attack-protection/bot-detection") || {
  fail "1.4 Unable to retrieve bot detection settings"
  increment_failed; summary; exit 0
}

# HTH Guide Excerpt: begin api-configure-bot-detection
# Configure bot detection with risk-based challenges
info "1.4 Configuring bot detection..."
RESPONSE=$(a0_patch "/attack-protection/bot-detection" '{
  "bot_detection_level": "medium",
  "challenge_password_policy": "when_risky",
  "challenge_passwordless_policy": "when_risky",
  "challenge_password_reset_policy": "when_risky",
  "monitoring_mode_enabled": false
}') || {
  fail "1.4 Failed to configure bot detection"
  increment_failed; summary; exit 0
}
# HTH Guide Excerpt: end api-configure-bot-detection

pass "1.4 Bot detection configured"
increment_applied
summary
