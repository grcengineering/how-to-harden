#!/usr/bin/env bash
# HTH BeyondTrust Control 1.01: Enforce Multi-Factor Authentication for All Access
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# https://howtoharden.com/guides/beyondtrust/#11-enforce-multi-factor-authentication-for-all-access

# HTH Guide Excerpt: begin api-configure-saml-mfa
# BeyondTrust API - Configure SAML provider
curl -X POST "https://${BEYONDTRUST_HOST}/api/config/security-provider" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "saml",
    "name": "Corporate SSO",
    "idpEntityId": "https://idp.company.com",
    "ssoUrl": "https://idp.company.com/saml/sso",
    "certificate": "-----BEGIN CERTIFICATE-----...",
    "signatureAlgorithm": "RSA-SHA256",
    "requireMfa": true
  }'
# HTH Guide Excerpt: end api-configure-saml-mfa
