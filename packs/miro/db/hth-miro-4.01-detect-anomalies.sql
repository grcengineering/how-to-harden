-- =============================================================================
-- HTH Miro Detection & Monitoring Queries
-- Vendor: miro | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect board sharing changes
SELECT user_email, board_name, share_type
FROM miro_audit_log
WHERE action = 'board_share_change'
  AND share_type = 'public'
  AND timestamp > NOW() - INTERVAL '7 days';

-- Detect bulk exports
SELECT user_email, export_count
FROM miro_audit_log
WHERE action = 'board_export'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_email
HAVING export_count > 10;
-- HTH Guide Excerpt: end db-detect-anomalies
