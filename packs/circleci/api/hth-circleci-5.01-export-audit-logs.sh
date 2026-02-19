#!/usr/bin/env bash
# HTH CircleCI Control 5.01: Enable Audit Logging — Export to SIEM
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/circleci/#51-enable-audit-logging
#
# Deploy: Run as scheduled job to export audit logs

# HTH Guide Excerpt: begin api-export-audit-logs
# CircleCI API - Export audit logs
curl -X GET "https://circleci.com/api/v2/organization/${ORG_ID}/audit-log?start-time=${START}" \
  -H "Circle-Token: ${API_TOKEN}" \
  | jq '.items[]'
# HTH Guide Excerpt: end api-export-audit-logs
