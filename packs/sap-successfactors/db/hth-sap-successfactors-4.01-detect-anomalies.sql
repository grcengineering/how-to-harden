-- =============================================================================
-- HTH SAP SuccessFactors Control 4.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk employee data access
SELECT user_id, api_endpoint, COUNT(*) as requests
FROM sf_audit_log
WHERE api_endpoint LIKE '%Employee%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id, api_endpoint
HAVING COUNT(*) > 100;
-- HTH Guide Excerpt: end db-detect-anomalies
