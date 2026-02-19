-- =============================================================================
-- HTH BambooHR Detection & Monitoring Queries
-- Vendor: bamboohr | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk data exports
SELECT user_email, report_name, record_count
FROM bamboo_activity
WHERE action = 'report_export'
  AND record_count > 100
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect API abuse
SELECT api_key, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key, endpoint
HAVING COUNT(*) > 500;
-- HTH Guide Excerpt: end db-detect-anomalies
