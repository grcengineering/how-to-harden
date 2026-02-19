-- =============================================================================
-- HTH Vercel Control 4.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect unauthorized deployments
SELECT user_email, project, environment, timestamp
FROM vercel_audit_log
WHERE action = 'deployment.created'
  AND environment = 'production'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect environment variable changes
SELECT user_email, project, variable_name
FROM vercel_audit_log
WHERE action LIKE '%environment_variable%'
  AND timestamp > NOW() - INTERVAL '7 days';
-- HTH Guide Excerpt: end db-detect-anomalies
