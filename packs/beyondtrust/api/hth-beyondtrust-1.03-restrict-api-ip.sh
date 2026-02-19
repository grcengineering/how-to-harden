#!/usr/bin/env bash
# HTH BeyondTrust Control 1.03: Configure IP-Based Access Restrictions
# Profile: L1 | NIST: AC-3(7), SC-7
# https://howtoharden.com/guides/beyondtrust/#13-configure-ip-based-access-restrictions

# HTH Guide Excerpt: begin api-restrict-api-ip
# API configuration - Restrict API key to specific IPs
curl -X PUT "https://${BEYONDTRUST_HOST}/api/config/api-keys/${KEY_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Integration-ServiceNow",
    "allowedIps": [
      "10.0.1.0/24",
      "203.0.113.50/32"
    ],
    "enabled": true
  }'
# HTH Guide Excerpt: end api-restrict-api-ip
