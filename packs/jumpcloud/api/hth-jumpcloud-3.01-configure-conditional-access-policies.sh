#!/usr/bin/env bash
# HTH JumpCloud Control 3.1: Configure Conditional Access Policies
# Profile: L2 | NIST: AC-2(11) | CIS: 6.4
# https://howtoharden.com/guides/jumpcloud/#31-configure-conditional-access-policies
source "$(dirname "$0")/common.sh"

banner "3.1: Configure Conditional Access Policies"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "3.1 Creating conditional access policies..."

# HTH Guide Excerpt: begin api-create-conditional-access
# Create IP list for trusted corporate networks
EXISTING_LIST=$(jc_get_v2 "/iplists" | jq -r '.[] | select(.name == "HTH: Corporate IPs") | .id') || true

if [ -z "${EXISTING_LIST}" ]; then
  info "3.1 Creating corporate IP list..."
  IP_LIST=$(jc_post_v2 "/iplists" '{
    "name": "HTH: Corporate IPs",
    "description": "Trusted corporate network ranges",
    "ips": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }') || {
    fail "3.1 Failed to create IP list"
    increment_failed; summary; exit 0
  }
  EXISTING_LIST=$(echo "${IP_LIST}" | jq -r '.id')
  pass "3.1 Corporate IP list created (id: ${EXISTING_LIST})"
fi

# Create policy: require MFA from non-corporate networks
EXISTING_POLICY=$(jc_get_v2 "/authn/policies" | jq -r '.[] | select(.name == "HTH: MFA Outside Corporate") | .id') || true

if [ -n "${EXISTING_POLICY}" ]; then
  info "3.1 Conditional access policy already exists (id: ${EXISTING_POLICY})"
else
  info "3.1 Creating conditional access policy..."
  RESPONSE=$(jc_post_v2 "/authn/policies" "$(jq -n --arg list_id "${EXISTING_LIST}" '{
    "name": "HTH: MFA Outside Corporate",
    "type": "user_portal",
    "disabled": false,
    "conditions": {
      "not": {
        "ipAddressIn": [$list_id]
      }
    },
    "effect": {
      "action": "allow",
      "obligations": {
        "mfa": { "required": true },
        "mfaFactors": ["TOTP", "WEBAUTHN"],
        "userVerification": { "requirement": "required" }
      }
    },
    "targets": {
      "resources": [{ "type": "user_portal" }]
    }
  }')") || {
    fail "3.1 Failed to create conditional access policy"
    increment_failed; summary; exit 0
  }
  pass "3.1 Conditional access policy created"
fi

increment_applied
# HTH Guide Excerpt: end api-create-conditional-access

summary
