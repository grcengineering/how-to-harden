#!/usr/bin/env bash
# HTH HubSpot Control 3.1: Secure Private App Tokens
# Profile: L1 | NIST: IA-5
# https://howtoharden.com/guides/hubspot/#31-secure-private-app-tokens

# HTH Guide Excerpt: begin cli-list-private-apps
# List private apps via API
curl -X GET "https://api.hubapi.com/integrations/v1/apps" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
# HTH Guide Excerpt: end cli-list-private-apps
