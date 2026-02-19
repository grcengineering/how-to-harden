#!/usr/bin/env bash
# HTH Workato Control 2.01: Configure Role-Based Access Control
# Profile: L1 | NIST: AC-6
# https://howtoharden.com/guides/workato/#21-configure-role-based-access-control

# HTH Guide Excerpt: begin api-list-roles
# List all custom roles in the workspace
curl -s "https://www.workato.com/api/roles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, description}'
# HTH Guide Excerpt: end api-list-roles

# HTH Guide Excerpt: begin api-get-role
# Get details of a specific role
curl -s "https://www.workato.com/api/roles/ROLE_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.'
# HTH Guide Excerpt: end api-get-role

# HTH Guide Excerpt: begin api-create-role
# Create a custom role with specific permissions
curl -s -X POST "https://www.workato.com/api/roles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Recipe Developer",
    "description": "Can build and test recipes but not deploy to production"
  }'
# HTH Guide Excerpt: end api-create-role
