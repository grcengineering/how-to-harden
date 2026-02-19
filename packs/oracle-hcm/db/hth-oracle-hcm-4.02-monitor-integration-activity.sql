-- HTH Oracle HCM Cloud Control 4.2: Monitor Integration Activity
-- Profile: L2
-- https://howtoharden.com/guides/oracle-hcm/#42-monitor-integration-activity

-- HTH Guide Excerpt: begin db-detect-unusual-api
-- Detect unusual API patterns
SELECT client_id, endpoint, COUNT(*) as requests
FROM api_access_log
WHERE timestamp > SYSDATE - INTERVAL '1' HOUR
GROUP BY client_id, endpoint
HAVING COUNT(*) > 500;

-- Detect off-hours HDL activity
SELECT user_name, file_name, timestamp
FROM hdl_audit_log
WHERE EXTRACT(HOUR FROM timestamp) NOT BETWEEN 8 AND 18;
-- HTH Guide Excerpt: end db-detect-unusual-api
