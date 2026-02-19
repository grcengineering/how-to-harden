-- =============================================================================
-- HTH Rippling Detection & Monitoring Queries
-- Vendor: rippling | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk data access
SELECT admin_email, action, record_count
FROM rippling_audit_log
WHERE action LIKE '%export%'
  AND record_count > 50
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect app provisioning changes
SELECT admin_email, app_name, action
FROM rippling_audit_log
WHERE action IN ('app.add_user', 'app.remove_user')
  AND timestamp > NOW() - INTERVAL '7 days';
-- HTH Guide Excerpt: end db-detect-anomalies
