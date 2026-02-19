-- =============================================================================
-- HTH ADP Detection & Monitoring Queries
-- Vendor: adp | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect unusual payroll changes
SELECT user_id, action, employee_id
FROM adp_audit_log
WHERE action IN ('bank_account_change', 'direct_deposit_change')
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect bulk W-2 access
SELECT user_id, COUNT(*) as w2_access_count
FROM adp_audit_log
WHERE action = 'w2_view'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 10;
-- HTH Guide Excerpt: end db-detect-anomalies
