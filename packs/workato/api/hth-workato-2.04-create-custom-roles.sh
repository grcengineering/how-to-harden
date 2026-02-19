#!/usr/bin/env bash
# HTH Workato Control 2.04: Configure Custom Roles
# Profile: L2 | NIST: AC-6(1)
# https://howtoharden.com/guides/workato/#24-configure-custom-roles

# HTH Guide Excerpt: begin api-create-custom-role
# Create a custom role with specific permissions
curl -s -X POST "https://www.workato.com/api/roles" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Deployment Approver",
    "description": "Can approve and execute deployments to production environments only"
  }'
# HTH Guide Excerpt: end api-create-custom-role
