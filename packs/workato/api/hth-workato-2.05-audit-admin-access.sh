#!/usr/bin/env bash
# HTH Workato Control 2.05: Limit Admin Access
# Profile: L1 | NIST: AC-6(5)
# https://howtoharden.com/guides/workato/#25-limit-admin-access

# HTH Guide Excerpt: begin api-audit-admins
# List all workspace collaborators and filter for admins
curl -s "https://www.workato.com/api/managed_users" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '[.result[] | select(.role_name == "Admin")] |
    "Admin count: \(length)", .[] | {id, name, email}'
# HTH Guide Excerpt: end api-audit-admins
