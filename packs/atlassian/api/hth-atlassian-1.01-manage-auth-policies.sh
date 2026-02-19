#!/usr/bin/env bash
# HTH Atlassian Control 1.1: Manage Authentication Policies
# Profile: L1 | NIST: IA-2(1)

# HTH Guide Excerpt: begin api-manage-auth-policies
# Get authentication policies
curl -X GET "https://api.atlassian.com/admin/v1/orgs/${ORG_ID}/policies/authentication" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Accept: application/json"

# Update authentication policy to enforce SSO
curl -X PUT "https://api.atlassian.com/admin/v1/orgs/${ORG_ID}/policies/authentication/${POLICY_ID}" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "authentication-policy",
    "attributes": {
      "ssoEnforced": true,
      "passwordAuthEnabled": false
    }
  }'
# HTH Guide Excerpt: end api-manage-auth-policies
