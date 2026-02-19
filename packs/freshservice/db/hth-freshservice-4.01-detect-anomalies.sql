-- =============================================================================
-- HTH Freshservice Detection & Monitoring Queries
-- Vendor: freshservice | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk asset exports
SELECT agent_email, export_type, record_count
FROM freshservice_audit
WHERE action = 'export'
  AND module = 'asset'
  AND record_count > 100;

-- Detect unusual API activity
SELECT api_key, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key, endpoint
HAVING COUNT(*) > 500;
-- HTH Guide Excerpt: end db-detect-anomalies
