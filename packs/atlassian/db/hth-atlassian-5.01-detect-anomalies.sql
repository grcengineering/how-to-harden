-- =============================================================================
-- HTH Atlassian Control 5.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk data access
SELECT user_id, action, COUNT(*) as action_count
FROM atlassian_audit_log
WHERE action IN ('content.view', 'issue.view')
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id, action
HAVING COUNT(*) > 100;

-- Detect permission changes
SELECT *
FROM atlassian_audit_log
WHERE action LIKE '%permission%'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect app installations
SELECT *
FROM atlassian_audit_log
WHERE action = 'app.installed'
  AND timestamp > NOW() - INTERVAL '7 days';
-- HTH Guide Excerpt: end db-detect-anomalies
