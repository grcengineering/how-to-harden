-- =============================================================================
-- HTH LaunchDarkly Control 4.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect production flag changes
SELECT user_email, flag_key, action
FROM launchdarkly_audit_log
WHERE environment = 'production'
  AND action IN ('updateFlag', 'toggleFlag')
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect bulk flag modifications
SELECT user_email, COUNT(*) as changes
FROM launchdarkly_audit_log
WHERE action LIKE '%Flag%'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 10;
-- HTH Guide Excerpt: end db-detect-anomalies
