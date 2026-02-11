#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 2: Network Access Controls
# Controls: 2.1, 2.3
# https://howtoharden.com/guides/okta/#2-network-access-controls
source "$(dirname "$0")/common.sh"

banner "Section 2: Network Access Controls"

# ===========================================================================
# 2.1 Configure IP Zones and Network Policies
# Profile: L1 | NIST: AC-3, SC-7
# ===========================================================================
control_2_1() {
  should_apply 1 || { increment_skipped; return 0; }
  info "2.1 Configuring IP zones and network policies..."

  # Check if Corporate Network zone already exists (idempotent)
  EXISTING_CORP=$(okta_get "/api/v1/zones" \
    | jq -r '.[] | select(.name == "Corporate Network") | .id' 2>/dev/null || true)

  if [ -n "${EXISTING_CORP}" ]; then
    pass "2.1 Corporate Network zone already exists (ID: ${EXISTING_CORP})"
  else
    # Create Corporate Network zone
    # NOTE: Replace gateway CIDRs with your actual corporate IP ranges
    info "2.1 Creating Corporate Network zone..."
    ZONE_RESPONSE=$(okta_post "/api/v1/zones" '{
      "type": "IP",
      "name": "Corporate Network",
      "status": "ACTIVE",
      "gateways": [
        {"type": "CIDR", "value": "203.0.113.0/24"},
        {"type": "CIDR", "value": "198.51.100.0/24"}
      ]
    }' 2>/dev/null) && {
      ZONE_ID=$(echo "${ZONE_RESPONSE}" | jq -r '.id' 2>/dev/null || true)
      pass "2.1 Corporate Network zone created (ID: ${ZONE_ID})"
      warn "2.1 IMPORTANT: Update the zone with your actual corporate IP ranges"
    } || {
      fail "2.1 Failed to create Corporate Network zone"
    }
  fi

  # Create TOR/Anonymizer block zone (idempotent)
  EXISTING_BLOCK=$(okta_get "/api/v1/zones" \
    | jq -r '.[] | select(.name == "Blocked - TOR and Anonymizers") | .id' 2>/dev/null || true)

  if [ -n "${EXISTING_BLOCK}" ]; then
    pass "2.1 TOR/Anonymizer block zone already exists (ID: ${EXISTING_BLOCK})"
  else
    info "2.1 Creating TOR/Anonymizer block zone..."
    okta_post "/api/v1/zones" '{
      "type": "DYNAMIC_V2",
      "name": "Blocked - TOR and Anonymizers",
      "status": "ACTIVE",
      "proxyType": "TorAnonymizer",
      "usage": "BLOCKLIST"
    }' > /dev/null 2>&1 && {
      pass "2.1 TOR/Anonymizer block zone created"
    } || {
      warn "2.1 Failed to create TOR block zone (may require Adaptive MFA license)"
    }
  fi

  increment_applied
}

# ===========================================================================
# 2.3 Configure Dynamic Network Zones and Anonymizer Blocking
# Profile: L2 | NIST: SC-7, AC-3
# ===========================================================================
control_2_3() {
  should_apply 2 || { increment_skipped; return 0; }
  info "2.3 Configuring Enhanced Dynamic Zones and anonymizer blocking..."

  # List all zones to find the Enhanced Dynamic Zone
  info "2.3 Searching for DefaultEnhancedDynamicZone..."
  ZONE_ID=$(okta_get "/api/v1/zones" \
    | jq -r '.[] | select(.name == "DefaultEnhancedDynamicZone") | .id' 2>/dev/null || true)

  if [ -z "${ZONE_ID}" ] || [ "${ZONE_ID}" = "null" ]; then
    warn "2.3 DefaultEnhancedDynamicZone not found (may require Adaptive MFA license)"
    increment_skipped
    return 0
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
    return 0
  fi

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
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_2_1
control_2_3

summary
