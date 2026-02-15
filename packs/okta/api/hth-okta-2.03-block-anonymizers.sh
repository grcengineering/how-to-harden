#!/usr/bin/env bash
# HTH Okta Control 2.3: Configure Dynamic Network Zones and Anonymizer Blocking
# Profile: L2 | NIST: SC-7, AC-3
# https://howtoharden.com/guides/okta/#23-configure-dynamic-network-zones-and-anonymizer-blocking
source "$(dirname "$0")/common.sh"

banner "2.3: Configure Dynamic Network Zones and Anonymizer Blocking"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.3 Configuring Enhanced Dynamic Zones and anonymizer blocking..."

# List all zones to find the Enhanced Dynamic Zone
info "2.3 Searching for DefaultEnhancedDynamicZone..."
ZONE_ID=$(okta_get "/api/v1/zones" \
  | jq -r '.[] | select(.name == "DefaultEnhancedDynamicZone") | .id' 2>/dev/null || true)

if [ -z "${ZONE_ID}" ] || [ "${ZONE_ID}" = "null" ]; then
  warn "2.3 DefaultEnhancedDynamicZone not found (may require Adaptive MFA license)"
  increment_skipped
  summary
  exit 0
fi

info "2.3 Found DefaultEnhancedDynamicZone (ID: ${ZONE_ID})"

# Check if already active with blocklist usage
ZONE_STATUS=$(okta_get "/api/v1/zones" \
  | jq -r ".[] | select(.id == \"${ZONE_ID}\") | .status" 2>/dev/null || echo "unknown")
ZONE_USAGE=$(okta_get "/api/v1/zones" \
  | jq -r ".[] | select(.id == \"${ZONE_ID}\") | .usage" 2>/dev/null || echo "unknown")

if [ "${ZONE_STATUS}" = "ACTIVE" ] && [ "${ZONE_USAGE}" = "BLOCKLIST" ]; then
  pass "2.3 Enhanced Dynamic Zone already active with blocklist usage"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-update-dynamic-zone
# Activate the zone as a blocklist
info "2.3 Activating DefaultEnhancedDynamicZone as blocklist..."
okta_put "/api/v1/zones/${ZONE_ID}" '{
  "type": "DYNAMIC_V2",
  "name": "DefaultEnhancedDynamicZone",
  "status": "ACTIVE",
  "usage": "BLOCKLIST",
  "proxyType": "TorAnonymizer"
}' > /dev/null 2>&1 && {
  pass "2.3 Enhanced Dynamic Zone activated with anonymizer blocking"
  increment_applied
} || {
  fail "2.3 Failed to activate Enhanced Dynamic Zone"
  increment_failed
}
# HTH Guide Excerpt: end api-update-dynamic-zone

summary
