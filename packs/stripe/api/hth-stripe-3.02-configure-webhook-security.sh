#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: stripe-3.2
#   guide:   https://howtoharden.com/guides/stripe/#32-configure-webhook-security
#   profile: L2
#   mode:    mutating
#   requires: STRIPE_SECRET_KEY(restricted key with Webhook Endpoints: Read; Write only for the opt-in create branch), STRIPE_SIEM_WEBHOOK_URL(optional; setting it enables the create branch)
# =============================================================================
# HTH Stripe Control 3.2: Configure Webhook Security
# Profile: L2 | NIST: SC-8 | CIS: 3.11
# https://howtoharden.com/guides/stripe/#32-configure-webhook-security
#
# WHY `mode: mutating` DESPITE A READ-ONLY DEFAULT. With STRIPE_SIEM_WEBHOOK_URL
# unset this pack only lists webhook endpoints. Setting it makes the pack create a
# webhook endpoint (POST /v1/webhook_endpoints), which changes account state, so
# the honest declaration is mutating. Run it against a sandbox first, and delete
# the endpoint afterwards if you were only testing.
#
# The signing secret Stripe returns on creation is never printed: reveal it from
# the destination in Workbench and put it straight into your secrets manager.
source "$(dirname "$0")/common.sh"

banner "3.2: Configure Webhook Security"
should_apply 2 || { increment_skipped; finish; }
info "3.2 Auditing webhook endpoints..."

# HTH Guide Excerpt: begin api-configure-webhook
# List existing webhook endpoints and flag disabled ones
WEBHOOKS=$(stripe_get "/webhook_endpoints?limit=100") || {
  fail "3.2 Unable to retrieve webhook endpoints (check the key and its Webhook Endpoints: Read permission)"
  increment_failed; finish
}

TOTAL=$(echo "${WEBHOOKS}" | jq '.data | length')
DISABLED=$(echo "${WEBHOOKS}" | jq '[.data[] | select(.status == "disabled")] | length')
info "3.2 Total webhook endpoints: ${TOTAL} (Stripe allows up to 16)"
info "3.2 Disabled endpoints: ${DISABLED}"

if [ "${DISABLED}" -gt 0 ]; then
  warn "3.2 Disabled webhook endpoints found — review and remove unused:"
  echo "${WEBHOOKS}" | jq -r '.data[] | select(.status == "disabled") | "  - \(.url) (id: \(.id))"'
fi

# Optional: create a webhook endpoint that forwards security-relevant events
if [ -n "${STRIPE_SIEM_WEBHOOK_URL:-}" ]; then
  case "${STRIPE_SIEM_WEBHOOK_URL}" in
    https://*) ;;
    *) fail "3.2 STRIPE_SIEM_WEBHOOK_URL must be an https:// URL"; increment_failed; finish ;;
  esac
  EXISTING=$(echo "${WEBHOOKS}" | jq -r --arg u "${STRIPE_SIEM_WEBHOOK_URL}" '.data[] | select(.url == $u) | .id')
  if [ -n "${EXISTING}" ]; then
    info "3.2 SIEM webhook already exists (id: ${EXISTING})"
  else
    info "3.2 Creating SIEM webhook for security events..."
    RESPONSE=$(curl -sf -X POST -K <(stripe_auth) "${STRIPE_BASE}/webhook_endpoints" \
      --data-urlencode "url=${STRIPE_SIEM_WEBHOOK_URL}" \
      --data-urlencode "enabled_events[]=account.updated" \
      --data-urlencode "enabled_events[]=account.application.authorized" \
      --data-urlencode "enabled_events[]=account.application.deauthorized" \
      --data-urlencode "enabled_events[]=account.external_account.created" \
      --data-urlencode "enabled_events[]=account.external_account.deleted" \
      --data-urlencode "enabled_events[]=person.created" \
      --data-urlencode "enabled_events[]=person.updated" \
      --data-urlencode "enabled_events[]=person.deleted" \
      --data-urlencode "enabled_events[]=payment_method.attached" \
      --data-urlencode "enabled_events[]=payment_method.detached" \
      --data-urlencode "enabled_events[]=identity.verification_session.created" \
      --data-urlencode "enabled_events[]=identity.verification_session.verified" \
      --data-urlencode "enabled_events[]=capability.updated" \
      --data-urlencode "description=HTH Security Events SIEM Webhook") || {
      fail "3.2 Failed to create SIEM webhook (the key needs Webhook Endpoints: Write)"
      increment_failed; finish
    }
    WEBHOOK_ID=$(echo "${RESPONSE}" | jq -r '.id')
    SECRET_LEN=$(echo "${RESPONSE}" | jq -r '.secret // "" | length')
    pass "3.2 SIEM webhook created (id: ${WEBHOOK_ID})"
    info "3.2 Signing secret returned (${SECRET_LEN} chars) and deliberately not printed —"
    info "3.2 reveal it from the destination in Workbench and store it in your secrets manager"
  fi
fi

pass "3.2 Webhook security audit complete"
increment_applied
# HTH Guide Excerpt: end api-configure-webhook

finish
