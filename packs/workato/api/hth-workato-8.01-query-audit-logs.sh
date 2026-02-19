#!/usr/bin/env bash
# HTH Workato Control 8.01: Configure Activity Audit Log
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/workato/#81-configure-activity-audit-log

# HTH Guide Excerpt: begin api-get-audit-logs
# Retrieve recent audit log events
curl -s "https://www.workato.com/api/activity_logs?page=1&per_page=100" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {
    timestamp: .created_at,
    user: .user_name,
    event: .event_type,
    resource: .resource_type,
    details: .details
  }'
# HTH Guide Excerpt: end api-get-audit-logs

# HTH Guide Excerpt: begin api-filter-admin-actions
# Filter for admin actions only
curl -s "https://www.workato.com/api/activity_logs?event_type=admin_action" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result[] | {timestamp: .created_at, user: .user_name, details: .details}'
# HTH Guide Excerpt: end api-filter-admin-actions

# HTH Guide Excerpt: begin api-export-audit-logs
# Export audit logs for compliance archive
curl -s "https://www.workato.com/api/activity_logs?page=1&per_page=500" \
  -H "Authorization: Bearer $WORKATO_API_TOKEN" | \
  jq '.result' > audit_log_$(date +%Y%m%d).json
# HTH Guide Excerpt: end api-export-audit-logs
