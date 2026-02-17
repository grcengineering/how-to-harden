#!/usr/bin/env bash
# HTH Stripe Control 3.1: Configure API Key Security
# Profile: L1 | NIST: SC-12 | CIS: 3.11
# https://howtoharden.com/guides/stripe/#31-configure-api-key-security
source "$(dirname "$0")/common.sh"

banner "3.1: Configure API Key Security"
should_apply 1 || { increment_skipped; summary; exit 0; }

# API key creation, rotation, restricted keys, and IP allowlisting
# are all Dashboard-only in Stripe. This script validates via events.
info "3.1 API key management is Dashboard-only (Developers > API keys)"
info "3.1 Restricted key creation is Dashboard-only"
info "3.1 IP allowlisting per key is Dashboard-only"
info "3.1 Auditing recent account events for key-related activity..."

# HTH Guide Excerpt: begin api-audit-account-events
# Monitor for account changes that may indicate key-related activity
# NOTE: Stripe has NO api_key.* event types — use account.updated instead
EVENTS=$(stripe_get "/events?type=account.updated&limit=10") || {
  fail "3.1 Unable to retrieve account events"
  increment_failed; summary; exit 0
}

EVENT_COUNT=$(echo "${EVENTS}" | jq '.data | length')
info "3.1 Recent account update events: ${EVENT_COUNT}"

if [ "${EVENT_COUNT}" -gt 0 ]; then
  info "3.1 Most recent account changes:"
  echo "${EVENTS}" | jq -r '.data[:5][] | "  - \(.created | todate): \(.type)"'
fi

pass "3.1 Account events audit complete — review API keys in Dashboard"
increment_applied
# HTH Guide Excerpt: end api-audit-account-events

summary
