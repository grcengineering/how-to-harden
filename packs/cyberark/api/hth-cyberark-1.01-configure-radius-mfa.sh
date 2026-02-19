#!/usr/bin/env bash
# HTH CyberArk Control 1.01: Enforce Multi-Factor Authentication for All Access
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# https://howtoharden.com/guides/cyberark/#11-enforce-multi-factor-authentication-for-all-access

set -euo pipefail

: "${PVWA_URL:?Set PVWA_URL (e.g. https://pvwa.company.com)}"
: "${AUTH_TOKEN:?Set AUTH_TOKEN (CyberArk session token)}"

# HTH Guide Excerpt: begin api-configure-mfa
# Configure RADIUS MFA authentication method via CyberArk REST API
curl -X PUT "https://${PVWA_URL}/PasswordVault/API/Configuration/AuthenticationMethods/radius" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "radius",
    "displayName": "RADIUS MFA",
    "enabled": true,
    "settings": {
      "server": "mfa.company.com",
      "port": 1812,
      "timeout": 60
    }
  }'
# HTH Guide Excerpt: end api-configure-mfa
