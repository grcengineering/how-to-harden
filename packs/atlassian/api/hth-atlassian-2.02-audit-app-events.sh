#!/usr/bin/env bash
# HTH Atlassian Control 2.2: Monitor App Activity
# Profile: L2 | NIST: AU-6

# HTH Guide Excerpt: begin api-audit-app-events
# Get app audit events
curl -X GET "https://api.atlassian.com/admin/v1/orgs/${ORG_ID}/audit-events?filter=app" \
  -H "Authorization: Bearer ${API_TOKEN}"
# HTH Guide Excerpt: end api-audit-app-events
