-- =============================================================================
-- HTH Gusto Detection & Monitoring Queries
-- Vendor: gusto | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bank account changes
SELECT admin_email, employee_name, change_type
FROM gusto_activity
WHERE action = 'bank_account_change'
  AND timestamp > NOW() - INTERVAL '7 days';

-- Detect unusual admin activity
SELECT admin_email, action, COUNT(*) as actions
FROM gusto_activity
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY admin_email, action
HAVING COUNT(*) > 50;
-- HTH Guide Excerpt: end db-detect-anomalies
