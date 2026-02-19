-- =============================================================================
-- HTH Smartsheet Detection & Monitoring Queries
-- Vendor: smartsheet | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk sharing changes
SELECT user_email, sheet_name, action
FROM smartsheet_activity
WHERE action LIKE '%share%'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect unusual export activity
SELECT user_email, export_count
FROM smartsheet_activity
WHERE action = 'export'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING export_count > 20;
-- HTH Guide Excerpt: end db-detect-anomalies
