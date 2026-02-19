-- =============================================================================
-- HTH CircleCI Control 5.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect context secret access outside normal hours
SELECT *
FROM circleci_audit_log
WHERE action = 'context.env_var.accessed'
  AND (EXTRACT(HOUR FROM timestamp) < 6
       OR EXTRACT(HOUR FROM timestamp) > 20);

-- Detect bulk secret access (potential exfiltration)
SELECT user_id, COUNT(*) as access_count
FROM circleci_audit_log
WHERE action LIKE '%secret%' OR action LIKE '%env_var%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 50;

-- Detect new API token creation
SELECT *
FROM circleci_audit_log
WHERE action = 'api_token.created'
  AND timestamp > NOW() - INTERVAL '24 hours';
-- HTH Guide Excerpt: end db-detect-anomalies
