-- =============================================================================
-- HTH Klaviyo Detection & Monitoring Queries
-- Vendor: klaviyo | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk profile exports
SELECT user_email, export_type, profile_count
FROM klaviyo_activity
WHERE action = 'export'
  AND profile_count > 10000
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect API abuse
SELECT api_key_prefix, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key_prefix, endpoint
HAVING COUNT(*) > 5000;
-- HTH Guide Excerpt: end db-detect-anomalies
