#!/usr/bin/env bash
# HTH LaunchDarkly Control 4.1: Audit Log
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/launchdarkly/#41-audit-log
source "$(dirname "$0")/common.sh"

banner "4.1: Audit Log"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Configuring audit log webhook for SIEM export..."

: "${LD_SIEM_WEBHOOK_URL:?Set LD_SIEM_WEBHOOK_URL to your SIEM webhook endpoint}"

# HTH Guide Excerpt: begin api-configure-audit-webhook
# Create a signed webhook for SIEM audit log streaming
EXISTING=$(ld_get "/webhooks" | jq -r '.items[] | select(.name == "HTH SIEM Webhook") | ._id') || true

if [ -n "${EXISTING}" ]; then
  info "4.1 SIEM webhook already exists (id: ${EXISTING})"
  pass "4.1 Audit log webhook configured"
  increment_applied
else
  WEBHOOK_SECRET="${LD_WEBHOOK_SECRET:-$(openssl rand -hex 32)}"
  info "4.1 Creating signed webhook for SIEM..."
  RESPONSE=$(ld_post "/webhooks" "$(jq -n \
    --arg url "${LD_SIEM_WEBHOOK_URL}" \
    --arg secret "${WEBHOOK_SECRET}" \
    '{
      "name": "HTH SIEM Webhook",
      "url": $url,
      "sign": true,
      "secret": $secret,
      "on": true,
      "tags": ["hth", "siem"],
      "statements": [
        {
          "effect": "allow",
          "actions": ["*"],
          "resources": ["proj/*"]
        }
      ]
    }'
  )") || {
    fail "4.1 Failed to create SIEM webhook"
    increment_failed; summary; exit 0
  }
  pass "4.1 SIEM webhook created"
  info "4.1 Webhook signing secret: ${WEBHOOK_SECRET}"
  increment_applied
fi
# HTH Guide Excerpt: end api-configure-audit-webhook

summary
