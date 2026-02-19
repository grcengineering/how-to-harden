#!/usr/bin/env bash
# HTH CyberArk Control 1.02: Implement Vault-Level Access Controls
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/cyberark/#12-implement-vault-level-access-controls

set -euo pipefail

: "${PVWA_URL:?Set PVWA_URL (e.g. https://pvwa.company.com)}"
: "${AUTH_TOKEN:?Set AUTH_TOKEN (CyberArk session token)}"

# HTH Guide Excerpt: begin api-create-safe
# Create safe with restricted access via REST API
curl -X POST "https://${PVWA_URL}/PasswordVault/API/Safes" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "safeName": "Windows-DomainAdmins",
    "description": "Domain Administrator credentials - requires approval",
    "olacEnabled": true,
    "managingCPM": "PasswordManager",
    "numberOfVersionsRetention": 10,
    "numberOfDaysRetention": 30
  }'

# Add member with limited permissions
curl -X POST "https://${PVWA_URL}/PasswordVault/API/Safes/Windows-DomainAdmins/Members" \
  -H "Authorization: ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "memberName": "WindowsAdmins",
    "memberType": "Group",
    "permissions": {
      "useAccounts": true,
      "retrieveAccounts": true,
      "listAccounts": true,
      "addAccounts": false,
      "updateAccountContent": false,
      "deleteAccounts": false,
      "manageSafe": false,
      "requestsAuthorizationLevel1": true
    }
  }'
# HTH Guide Excerpt: end api-create-safe
