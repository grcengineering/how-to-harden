#!/usr/bin/env bash
# HTH Ping Identity Control 3.01: Configure Secure OAuth Settings
# Profile: L1 | NIST: IA-5(13), SC-23
# https://howtoharden.com/guides/ping-identity/#31-configure-secure-oauth-settings

# HTH Guide Excerpt: begin configure-oauth-app
# PingOne - Configure OAuth application
curl -X PUT "https://api.pingone.com/v1/environments/${ENV_ID}/applications/${APP_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Secure App",
    "protocol": "OPENID_CONNECT",
    "tokenEndpointAuthMethod": "CLIENT_SECRET_POST",
    "grantTypes": ["AUTHORIZATION_CODE", "REFRESH_TOKEN"],
    "pkceEnforcement": "S256_REQUIRED",
    "accessTokenValiditySeconds": 3600,
    "refreshTokenValiditySeconds": 86400,
    "refreshTokenRollingEnabled": true
  }'
# HTH Guide Excerpt: end configure-oauth-app
