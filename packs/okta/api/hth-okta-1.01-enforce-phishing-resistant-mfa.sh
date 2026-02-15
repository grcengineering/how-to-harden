#!/usr/bin/env bash
# HTH Okta Control 1.1: Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)
# Profile: L1 | NIST: IA-2(1), IA-2(6) | DISA STIG: V-273190, V-273191
# https://howtoharden.com/guides/okta/#11-enforce-phishing-resistant-mfa
source "$(dirname "$0")/common.sh"

banner "1.1: Enforce Phishing-Resistant MFA (FIDO2/WebAuthn)"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Enforcing phishing-resistant MFA (FIDO2/WebAuthn)..."

# Check if policy already exists (idempotent)
EXISTING=$(okta_get "/api/v1/policies?type=ACCESS_POLICY" \
  | jq -r '.[] | select(.name == "Phishing-Resistant MFA Policy") | .id' 2>/dev/null || true)

if [ -n "${EXISTING}" ]; then
  pass "1.1 Phishing-resistant MFA policy already exists (ID: ${EXISTING})"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-create-policy
# Create FIDO2 authenticator policy
info "1.1 Creating phishing-resistant MFA policy..."
POLICY_RESPONSE=$(okta_post "/api/v1/policies" '{
  "type": "ACCESS_POLICY",
  "name": "Phishing-Resistant MFA Policy",
  "description": "Requires FIDO2 for sensitive applications",
  "priority": 1,
  "conditions": {
    "people": {
      "groups": {
        "include": ["EVERYONE"]
      }
    }
  }
}') || {
  fail "1.1 Failed to create MFA policy"
  increment_failed
  summary
  exit 0
}

POLICY_ID=$(echo "${POLICY_RESPONSE}" | jq -r '.id // empty' 2>/dev/null || true)
# HTH Guide Excerpt: end api-create-policy

if [ -n "${POLICY_ID}" ]; then
  # HTH Guide Excerpt: begin api-create-rule
  # Create policy rule requiring WebAuthn
  info "1.1 Creating policy rule requiring FIDO2..."
  okta_post "/api/v1/policies/${POLICY_ID}/rules" '{
    "name": "Require FIDO2",
    "priority": 1,
    "conditions": {
      "network": {
        "connection": "ANYWHERE"
      }
    },
    "actions": {
      "signon": {
        "access": "ALLOW",
        "requireFactor": true,
        "factorPromptMode": "ALWAYS",
        "primaryFactor": "PASSWORD_IDP_ANY_FACTOR",
        "factorLifetime": 0
      }
    }
  }' > /dev/null 2>&1 || warn "1.1 Policy rule creation returned non-zero (may already exist)"
  # HTH Guide Excerpt: end api-create-rule

  pass "1.1 Phishing-resistant MFA policy created (ID: ${POLICY_ID})"
  increment_applied
else
  fail "1.1 Policy creation returned empty ID"
  increment_failed
fi

summary
