#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: stripe-3.1
#   guide:   https://howtoharden.com/guides/stripe/#31-configure-api-key-security
#   profile: L1
#   mode:    read-only
#   requires: STRIPE_SECRET_KEY(restricted key with Events: Read; nothing else is needed)
# =============================================================================
# HTH Stripe Control 3.1: Configure API Key Security
# Profile: L1 | NIST: SC-12 | CIS: 3.11
# https://howtoharden.com/guides/stripe/#31-configure-api-key-security
#
# SCOPE — what this pack can and cannot see. It reads account.updated events,
# which record changes to the Account object (business details, capabilities,
# settings). API key lifecycle (created, rotated, expired, viewed) is NOT carried
# on the v1 Events API: Stripe records it in the Dashboard's Security history and
# in the Activity Logs API (GET /v2/iam/activity_logs, public preview,
# https://docs.stripe.com/activity-logs), which needs a key with the
# "Activity logs: Read" permission. Review key lifecycle there.
source "$(dirname "$0")/common.sh"

banner "3.1: Configure API Key Security"
should_apply 1 || { increment_skipped; finish; }

# Key creation, rotation, expiry and access policies are Dashboard operations.
info "3.1 API keys are managed in the Dashboard (Developers > API keys)"
info "3.1 Network restrictions are access policies (Developers > Access policies)"
info "3.1 Key lifecycle events: Security history or the Activity Logs API (preview)"
info "3.1 Auditing recent account configuration changes (account.updated)..."

# HTH Guide Excerpt: begin api-audit-account-events
# List recent account configuration changes. The v1 Events API has no api_key.*
# event types — key lifecycle lives in Security history / the Activity Logs API.
EVENTS=$(stripe_get "/events?type=account.updated&limit=10") || {
  fail "3.1 Unable to retrieve account events (check the key and its Events: Read permission)"
  increment_failed; finish
}

EVENT_COUNT=$(echo "${EVENTS}" | jq '.data | length')
info "3.1 Recent account.updated events: ${EVENT_COUNT}"

if [ "${EVENT_COUNT}" -gt 0 ]; then
  info "3.1 Most recent account changes:"
  echo "${EVENTS}" | jq -r '.data[:5][] | "  - \(.created | todate): \(.type)"'
fi

pass "3.1 Account configuration audit complete — review key lifecycle in Security history"
increment_applied
# HTH Guide Excerpt: end api-audit-account-events

finish
