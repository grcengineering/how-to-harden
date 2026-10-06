#!/usr/bin/env bash
# HTH Okta Control 2.3: Configure Dynamic Network Zones and Anonymizer Blocking
# Profile: L2 | NIST: SC-7, AC-3
# https://howtoharden.com/guides/okta/#23-configure-dynamic-network-zones-and-anonymizer-blocking
#
# DefaultEnhancedDynamicZone is a system DYNAMIC_V2 blocklist zone that ships
# INACTIVE; its only change in the console is its status. Activation uses the
# zone lifecycle endpoint (Okta Management API, NetworkZone: activateNetworkZone).
source "$(dirname "$0")/common.sh"

banner "2.3: Configure Dynamic Network Zones and Anonymizer Blocking"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.3 Configuring Enhanced Dynamic Zones and anonymizer blocking..."

# Find the default enhanced dynamic zone (a failed read stops the pack).
# Admins can rename it, so match the system DYNAMIC_V2 blocklist zone as well.
info "2.3 Searching for DefaultEnhancedDynamicZone..."
ZONE=$(okta_get "/api/v1/zones" | jq -c '
  [.[] | select(.name == "DefaultEnhancedDynamicZone"
                or (.system == true and .type == "DYNAMIC_V2" and .usage == "BLOCKLIST"))][0] // empty')

if [ -z "${ZONE}" ]; then
  fail "2.3 No system Enhanced Dynamic Zone found in the zone list -- check the org's edition"
  increment_failed
  summary
fi

ZONE_ID=$(printf '%s' "${ZONE}" | jq -r '.id')
ZONE_STATUS=$(printf '%s' "${ZONE}" | jq -r '.status')
info "2.3 Found DefaultEnhancedDynamicZone (ID: ${ZONE_ID}, status: ${ZONE_STATUS})"

if [ "${ZONE_STATUS}" = "ACTIVE" ]; then
  pass "2.3 Enhanced Dynamic Zone already active (blocks anonymizers on every Okta endpoint)"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-update-dynamic-zone
# Activate the default enhanced dynamic zone (a pre-authentication blocklist)
info "2.3 Activating DefaultEnhancedDynamicZone..."
if okta_post "/api/v1/zones/${ZONE_ID}/lifecycle/activate" '{}' > /dev/null; then
  pass "2.3 Enhanced Dynamic Zone activated with anonymizer blocking"
  increment_applied
else
  fail "2.3 Failed to activate Enhanced Dynamic Zone"
  increment_failed
fi
# HTH Guide Excerpt: end api-update-dynamic-zone

summary
