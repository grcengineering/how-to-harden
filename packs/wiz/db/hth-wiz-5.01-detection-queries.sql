-- HTH Wiz Control 5.1: Audit Logging
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/wiz/#51-audit-logging

-- HTH Guide Excerpt: begin db-detect-unusual-access
-- Detect unusual data access
SELECT user_email, COUNT(*) as query_count
FROM wiz_audit_log
WHERE action_type = 'QUERY'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 100;

-- Detect API access from new IPs
SELECT service_account, source_ip, COUNT(*) as requests
FROM wiz_audit_log
WHERE action_type = 'API_REQUEST'
  AND source_ip NOT IN (SELECT DISTINCT source_ip FROM historical_ips)
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY service_account, source_ip;
-- HTH Guide Excerpt: end db-detect-unusual-access
