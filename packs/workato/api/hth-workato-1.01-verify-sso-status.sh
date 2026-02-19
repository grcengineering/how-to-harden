#!/usr/bin/env bash
# HTH Workato Control 1.01: Configure SAML Single Sign-On
# Profile: L1 | NIST: IA-2, IA-8
# https://howtoharden.com/guides/workato/#11-configure-saml-single-sign-on

# HTH Guide Excerpt: begin api-verify-sso-status
# List all workspace members and check their authentication method
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" | \
  jq '.result[] | {id: .id, email: .email, name: .name}'
# HTH Guide Excerpt: end api-verify-sso-status
