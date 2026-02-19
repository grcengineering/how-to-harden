-- =============================================================================
-- HTH Snyk Control 4.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk vulnerability exports
SELECT user_email, action, project_count
FROM snyk_audit_log
WHERE action = 'export'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_email
HAVING project_count > 10;

-- Detect service account creation
SELECT admin_email, service_account_name, created_at
FROM snyk_audit_log
WHERE action = 'service_account.create'
  AND timestamp > NOW() - INTERVAL '7 days';
-- HTH Guide Excerpt: end db-detect-anomalies
