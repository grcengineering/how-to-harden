#!/usr/bin/env bash
# HTH Okta Control 2.1: Configure IP Zones and Network Policies
# Profile: L1 | NIST: AC-3, SC-7
# https://howtoharden.com/guides/okta/#21-configure-ip-zones-and-network-policies
source "$(dirname "$0")/common.sh"

banner "2.1: Configure IP Zones and Network Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Configuring IP zones and network policies..."

# Check if Corporate Network zone already exists (idempotent)
EXISTING_CORP=$(okta_get "/api/v1/zones" \
  | jq -r '.[] | select(.name == "Corporate Network") | .id' 2>/dev/null || true)

if [ -n "${EXISTING_CORP}" ]; then
  pass "2.1 Corporate Network zone already exists (ID: ${EXISTING_CORP})"
else
  # HTH Guide Excerpt: begin api-create-corporate-zone
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
  # HTH Guide Excerpt: end api-create-corporate-zone
fi

# Create TOR/Anonymizer block zone (idempotent)
EXISTING_BLOCK=$(okta_get "/api/v1/zones" \
  | jq -r '.[] | select(.name == "Blocked - TOR and Anonymizers") | .id' 2>/dev/null || true)

if [ -n "${EXISTING_BLOCK}" ]; then
  pass "2.1 TOR/Anonymizer block zone already exists (ID: ${EXISTING_BLOCK})"
else
  # HTH Guide Excerpt: begin api-create-anonymizer-zone
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
  # HTH Guide Excerpt: end api-create-anonymizer-zone
fi

increment_applied

summary
