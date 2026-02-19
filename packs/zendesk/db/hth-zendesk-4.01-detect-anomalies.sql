-- =============================================================================
-- HTH Zendesk Detection & Monitoring Queries
-- Vendor: zendesk | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk ticket exports
SELECT user_email, action, COUNT(*) as exports
FROM zendesk_audit_log
WHERE action = 'ticket_export'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_email, action
HAVING COUNT(*) > 10;

-- Detect API abuse
SELECT api_token, endpoint, COUNT(*) as requests
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_token, endpoint
HAVING COUNT(*) > 1000;
-- HTH Guide Excerpt: end db-detect-anomalies
