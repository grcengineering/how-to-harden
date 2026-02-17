#!/usr/bin/env bash
# HTH Stripe Control 3.2: Configure Webhook Security
# Profile: L2 | NIST: SC-8 | CIS: 3.11
# https://howtoharden.com/guides/stripe/#32-configure-webhook-security
source "$(dirname "$0")/common.sh"

banner "3.2: Configure Webhook Security"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.2 Auditing and configuring webhook endpoints..."

# HTH Guide Excerpt: begin api-configure-webhook
# List existing webhooks and check for unsigned endpoints
WEBHOOKS=$(stripe_get "/webhook_endpoints?limit=100") || {
  fail "3.2 Unable to retrieve webhook endpoints"
  increment_failed; summary; exit 0
}

TOTAL=$(echo "${WEBHOOKS}" | jq '.data | length')
DISABLED=$(echo "${WEBHOOKS}" | jq '[.data[] | select(.status == "disabled")] | length')
info "3.2 Total webhook endpoints: ${TOTAL}"
info "3.2 Disabled endpoints: ${DISABLED}"

if [ "${DISABLED}" -gt 0 ]; then
  warn "3.2 Disabled webhook endpoints found — review and remove unused:"
  echo "${WEBHOOKS}" | jq -r '.data[] | select(.status == "disabled") | "  - \(.url) (id: \(.id))"'
fi

# Create a SIEM webhook for security events if URL is provided
if [ -n "${STRIPE_SIEM_WEBHOOK_URL:-}" ]; then
  EXISTING=$(echo "${WEBHOOKS}" | jq -r ".data[] | select(.url == \"${STRIPE_SIEM_WEBHOOK_URL}\") | .id")
  if [ -n "${EXISTING}" ]; then
    info "3.2 SIEM webhook already exists (id: ${EXISTING})"
  else
    info "3.2 Creating SIEM webhook for security events..."
    RESPONSE=$(stripe_post "/webhook_endpoints" "$(cat <<'PARAMS'
url=${STRIPE_SIEM_WEBHOOK_URL}&\
enabled_events[]=account.updated&\
enabled_events[]=account.application.authorized&\
enabled_events[]=account.application.deauthorized&\
enabled_events[]=account.external_account.created&\
enabled_events[]=account.external_account.deleted&\
enabled_events[]=person.created&\
enabled_events[]=person.updated&\
enabled_events[]=person.deleted&\
enabled_events[]=payment_method.attached&\
enabled_events[]=payment_method.detached&\
enabled_events[]=identity.verification_session.created&\
enabled_events[]=identity.verification_session.verified&\
enabled_events[]=capability.updated&\
description=HTH Security Events SIEM Webhook
PARAMS
    )") || {
      fail "3.2 Failed to create SIEM webhook"
      increment_failed; summary; exit 0
    }
    WEBHOOK_ID=$(echo "${RESPONSE}" | jq -r '.id')
    WEBHOOK_SECRET=$(echo "${RESPONSE}" | jq -r '.secret')
    pass "3.2 SIEM webhook created (id: ${WEBHOOK_ID})"
    info "3.2 Webhook signing secret: ${WEBHOOK_SECRET}"
    info "3.2 IMPORTANT: Store this secret securely for signature verification"
  fi
fi

pass "3.2 Webhook security audit complete"
increment_applied
# HTH Guide Excerpt: end api-configure-webhook

summary
