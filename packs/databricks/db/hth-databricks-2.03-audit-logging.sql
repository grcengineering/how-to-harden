-- =============================================================================
-- HTH Databricks Control 2.3: Audit Logging for Data Access
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/databricks/#23-audit-logging-for-data-access
-- =============================================================================

-- HTH Guide Excerpt: begin db-query-audit-logs
-- Query data access audit logs
SELECT
    event_time,
    user_identity.email as user_email,
    action_name,
    request_params.full_name_arg as table_accessed,
    source_ip_address
FROM system.access.audit
WHERE action_name IN ('getTable', 'commandSubmit')
    AND event_time > current_timestamp() - INTERVAL 24 HOURS
ORDER BY event_time DESC;
-- HTH Guide Excerpt: end db-query-audit-logs
