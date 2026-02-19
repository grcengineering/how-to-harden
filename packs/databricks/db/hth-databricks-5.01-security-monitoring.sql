-- =============================================================================
-- HTH Databricks Control 5.1: Security Monitoring
-- Profile: L1 | NIST: SI-4
-- https://howtoharden.com/guides/databricks/#51-security-monitoring
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-bulk-access
-- Detect bulk data access (>100 queries/hour to a single table)
SELECT
    user_identity.email,
    request_params.full_name_arg as table_name,
    COUNT(*) as access_count
FROM system.access.audit
WHERE action_name = 'commandSubmit'
    AND event_time > current_timestamp() - INTERVAL 1 HOUR
GROUP BY user_identity.email, request_params.full_name_arg
HAVING COUNT(*) > 100;
-- HTH Guide Excerpt: end db-detect-bulk-access

-- HTH Guide Excerpt: begin db-detect-unusual-exports
-- Detect unusual export operations (last 24 hours)
SELECT *
FROM system.access.audit
WHERE action_name IN ('downloadResults', 'exportResults')
    AND event_time > current_timestamp() - INTERVAL 24 HOURS
ORDER BY event_time DESC;
-- HTH Guide Excerpt: end db-detect-unusual-exports

-- HTH Guide Excerpt: begin db-detect-service-principal-anomalies
-- Detect service principal anomalies (access from untrusted IPs)
SELECT
    user_identity.email,
    source_ip_address,
    COUNT(*) as request_count
FROM system.access.audit
WHERE user_identity.email LIKE 'svc-%'
    AND source_ip_address NOT IN (SELECT ip FROM trusted_ips)
    AND event_time > current_timestamp() - INTERVAL 1 HOUR
GROUP BY user_identity.email, source_ip_address;
-- HTH Guide Excerpt: end db-detect-service-principal-anomalies
