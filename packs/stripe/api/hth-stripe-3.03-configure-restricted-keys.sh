#!/usr/bin/env bash
# HTH Stripe Control 3.3: Configure Restricted Keys
# Profile: L2 | NIST: AC-6 | CIS: 5.4
# https://howtoharden.com/guides/stripe/#33-configure-restricted-keys
source "$(dirname "$0")/common.sh"

banner "3.3: Configure Restricted Keys"
should_apply 2 || { increment_skipped; summary; exit 0; }

# Restricted key creation is Dashboard-only in Stripe.
# This script provides validation guidance.
info "3.3 Restricted key creation is Dashboard-only (Developers > API keys)"
info "3.3 Validating current key scope by testing restricted operations..."

# HTH Guide Excerpt: begin api-validate-key-scope
# Test if the current key has overly broad permissions
# A restricted key should fail on resources it doesn't need
info "3.3 Testing key permissions scope..."

# Try to list customers (should fail if key is properly restricted)
if stripe_get "/customers?limit=1" > /dev/null 2>&1; then
  warn "3.3 Current key can list customers — may be overly permissive"
else
  pass "3.3 Current key cannot list customers — properly scoped"
fi

# Try to list payment intents
if stripe_get "/payment_intents?limit=1" > /dev/null 2>&1; then
  warn "3.3 Current key can list payment intents — review if needed"
else
  pass "3.3 Current key cannot list payment intents — properly scoped"
fi

# Try to list webhook endpoints (meta-permission check)
if stripe_get "/webhook_endpoints?limit=1" > /dev/null 2>&1; then
  info "3.3 Current key has webhook read access"
else
  info "3.3 Current key cannot list webhooks"
fi

pass "3.3 Key scope validation complete"
increment_applied
# HTH Guide Excerpt: end api-validate-key-scope

summary
