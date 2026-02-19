#!/usr/bin/env bash
# HTH Ping Identity Control 1.01: Enforce Phishing-Resistant MFA
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# https://howtoharden.com/guides/ping-identity/#11-enforce-phishing-resistant-mfa

# HTH Guide Excerpt: begin create-mfa-policy
# Create MFA policy requiring FIDO2
curl -X POST "https://api.pingone.com/v1/environments/${ENV_ID}/mfaPolicies" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Phishing-Resistant MFA",
    "enabled": true,
    "configuration": {
      "fido2": {
        "enabled": true,
        "required": true
      },
      "sms": {
        "enabled": false
      },
      "totp": {
        "enabled": false
      }
    }
  }'

# Assign to admin group
curl -X PUT "https://api.pingone.com/v1/environments/${ENV_ID}/groups/${ADMIN_GROUP_ID}/mfaPolicy" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "mfaPolicyId": "${MFA_POLICY_ID}"
  }'
# HTH Guide Excerpt: end create-mfa-policy
