-- =============================================================================
-- HTH BeyondTrust API Usage Anomaly Detection Queries
-- Vendor: beyondtrust | Section: 2.3
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-api-new-ips
-- Detect API access from new IPs
SELECT api_key_name, source_ip, COUNT(*) as requests
FROM api_access_log
WHERE source_ip NOT IN (
    SELECT DISTINCT source_ip
    FROM api_access_log
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL 7 DAY)
)
AND timestamp > DATE_SUB(NOW(), INTERVAL 1 DAY)
GROUP BY api_key_name, source_ip;
-- HTH Guide Excerpt: end db-detect-api-new-ips

-- HTH Guide Excerpt: begin db-detect-afterhours-api
-- Detect after-hours API usage
SELECT api_key_name, timestamp, endpoint, source_ip
FROM api_access_log
WHERE HOUR(timestamp) NOT BETWEEN 6 AND 20
    OR DAYOFWEEK(timestamp) IN (1, 7)
ORDER BY timestamp DESC
LIMIT 100;
-- HTH Guide Excerpt: end db-detect-afterhours-api

-- HTH Guide Excerpt: begin db-detect-bulk-access
-- Detect bulk data access patterns
SELECT api_key_name, endpoint, COUNT(*) as request_count
FROM api_access_log
WHERE timestamp > DATE_SUB(NOW(), INTERVAL 1 HOUR)
    AND endpoint LIKE '/api/sessions%'
GROUP BY api_key_name, endpoint
HAVING COUNT(*) > 50;
-- HTH Guide Excerpt: end db-detect-bulk-access
