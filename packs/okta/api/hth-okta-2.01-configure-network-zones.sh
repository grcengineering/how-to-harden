#!/usr/bin/env bash
# HTH Okta Control 2.1: Configure IP Zones and Network Policies
# Profile: L1 | NIST: AC-3, SC-7
# https://howtoharden.com/guides/okta/#21-configure-ip-zones-and-network-policies
#
# Zone shapes: Okta Management API, NetworkZone. An IP zone lists gateway CIDRs;
# a DYNAMIC zone matches proxy type (Any / Tor / NotTorAnonymizer), locations,
# and ASNs. usage "BLOCKLIST" makes a zone a pre-authentication block on every
# Okta endpoint (it can no longer be used in policy rules).
source "$(dirname "$0")/common.sh"

banner "2.1: Configure IP Zones and Network Policies"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Configuring IP zones and network policies..."

failed=0

# Read existing zones once (a failed read stops the pack)
ZONES=$(okta_get "/api/v1/zones")

# Check if Corporate Network zone already exists (idempotent)
EXISTING_CORP=$(printf '%s' "${ZONES}" | jq -r '.[] | select(.name == "Corporate Network") | .id')

if [ -n "${EXISTING_CORP}" ]; then
  pass "2.1 Corporate Network zone already exists (ID: ${EXISTING_CORP})"
else
  # HTH Guide Excerpt: begin api-create-corporate-zone
  # Create Corporate Network zone
  # NOTE: Replace gateway CIDRs with your actual corporate IP ranges
  info "2.1 Creating Corporate Network zone..."
  if ZONE_RESPONSE=$(okta_post "/api/v1/zones" '{
    "type": "IP",
    "name": "Corporate Network",
    "status": "ACTIVE",
    "usage": "POLICY",
    "gateways": [
      {"type": "CIDR", "value": "203.0.113.0/24"},
      {"type": "CIDR", "value": "198.51.100.0/24"}
    ]
  }'); then
    ZONE_ID=$(printf '%s' "${ZONE_RESPONSE}" | jq -r '.id')
    pass "2.1 Corporate Network zone created (ID: ${ZONE_ID})"
    warn "2.1 IMPORTANT: Update the zone with your actual corporate IP ranges"
  else
    fail "2.1 Failed to create Corporate Network zone"
    failed=$((failed + 1))
  fi
  # HTH Guide Excerpt: end api-create-corporate-zone
fi

# Create Tor anonymizer block zone (idempotent)
EXISTING_BLOCK=$(printf '%s' "${ZONES}" | jq -r '.[] | select(.name == "Blocked - Tor Anonymizers") | .id')

if [ -n "${EXISTING_BLOCK}" ]; then
  pass "2.1 Tor anonymizer block zone already exists (ID: ${EXISTING_BLOCK})"
else
  # HTH Guide Excerpt: begin api-create-anonymizer-zone
  # Dynamic zone matching Tor anonymizer proxies, used as a blocklist
  info "2.1 Creating Tor anonymizer block zone..."
  if okta_post "/api/v1/zones" '{
    "type": "DYNAMIC",
    "name": "Blocked - Tor Anonymizers",
    "status": "ACTIVE",
    "usage": "BLOCKLIST",
    "proxyType": "Tor"
  }' > /dev/null; then
    pass "2.1 Tor anonymizer block zone created"
  else
    fail "2.1 Failed to create Tor anonymizer block zone"
    failed=$((failed + 1))
  fi
  # HTH Guide Excerpt: end api-create-anonymizer-zone
fi

if [ "${failed}" -eq 0 ]; then
  increment_applied
else
  increment_failed
fi

summary
