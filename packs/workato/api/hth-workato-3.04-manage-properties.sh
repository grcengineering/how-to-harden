#!/usr/bin/env bash
# HTH Workato Control 3.04: Protect Environment Properties
# Profile: L1 | NIST: SC-28
# https://howtoharden.com/guides/workato/#34-protect-environment-properties

# HTH Guide Excerpt: begin api-list-properties
# List all environment properties
curl -s "https://www.workato.com/api/properties" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {name, sensitive}'
# HTH Guide Excerpt: end api-list-properties

# HTH Guide Excerpt: begin api-create-sensitive-property
# Create or update a sensitive property
curl -s -X POST "https://www.workato.com/api/properties" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "API_SECRET_KEY",
    "value": "sk-abc123...",
    "sensitive": true
  }'
# HTH Guide Excerpt: end api-create-sensitive-property
