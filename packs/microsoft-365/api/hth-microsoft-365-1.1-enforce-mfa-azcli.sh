#!/usr/bin/env bash
# =============================================================================
# HTH Microsoft 365 Control 1.1: Enforce Phishing-Resistant MFA for All Users
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# Source: https://howtoharden.com/guides/microsoft-365/#11-enforce-phishing-resistant-mfa-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin api-enforce-mfa

# Create Conditional Access policy via Graph API
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" \
  --headers "Content-Type=application/json" \
  --body '{
    "displayName": "Require MFA for all users",
    "state": "enabled",
    "conditions": {
      "users": {
        "includeUsers": ["All"],
        "excludeUsers": ["BREAK_GLASS_ACCOUNT_ID"]
      },
      "applications": {
        "includeApplications": ["All"]
      }
    },
    "grantControls": {
      "operator": "OR",
      "builtInControls": ["mfa"]
    }
  }'

# HTH Guide Excerpt: end api-enforce-mfa
