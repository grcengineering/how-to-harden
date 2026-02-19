#!/usr/bin/env bash
# HTH Workato Control 5.01: Configure API Platform Security
# Profile: L2 | NIST: AC-3, SC-8
# https://howtoharden.com/guides/workato/#51-configure-api-platform-security

# HTH Guide Excerpt: begin api-list-clients
# List all API clients
curl -s "https://www.workato.com/api/api_clients" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, created_at}'
# HTH Guide Excerpt: end api-list-clients

# HTH Guide Excerpt: begin api-create-client
# Create a new API client
curl -s -X POST "https://www.workato.com/api/api_clients" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "partner-system-prod",
    "description": "Production API access for Partner System"
  }'
# HTH Guide Excerpt: end api-create-client

# HTH Guide Excerpt: begin api-list-access-profiles
# List API access profiles
curl -s "https://www.workato.com/api/api_access_profiles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, api_client_id, api_collection_ids}'
# HTH Guide Excerpt: end api-list-access-profiles
