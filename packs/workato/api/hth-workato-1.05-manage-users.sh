#!/usr/bin/env bash
# HTH Workato Control 1.05: Configure SCIM Provisioning
# Profile: L2 | NIST: AC-2(1)
# https://howtoharden.com/guides/workato/#15-configure-scim-provisioning

# HTH Guide Excerpt: begin api-list-users
# List all managed users
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {id, name, email, external_id}'
# HTH Guide Excerpt: end api-list-users

# HTH Guide Excerpt: begin api-add-user
# Add a managed user
curl -s -X POST "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "email": "jane.doe@company.com",
    "external_id": "ext-12345",
    "role_name": "Analyst"
  }'
# HTH Guide Excerpt: end api-add-user

# HTH Guide Excerpt: begin api-delete-user
# Delete a managed user (deprovision)
curl -s -X DELETE "https://www.workato.com/api/managed_users/USER_ID" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN"
# HTH Guide Excerpt: end api-delete-user
