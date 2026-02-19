-- =============================================================================
-- HTH SailPoint Detection & Monitoring Queries
-- Vendor: sailpoint | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect unusual account creation
SELECT created_by, COUNT(*) as account_count
FROM provisioning_events
WHERE action = 'CREATE'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY created_by
HAVING COUNT(*) > 10;

-- Detect certification modifications
SELECT admin_user, certification_name, action
FROM governance_events
WHERE action IN ('APPROVE_ALL', 'CERTIFICATION_MODIFY')
  AND timestamp > NOW() - INTERVAL '24 hours';
-- HTH Guide Excerpt: end db-detect-anomalies
