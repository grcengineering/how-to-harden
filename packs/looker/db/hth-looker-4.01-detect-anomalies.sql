-- =============================================================================
-- HTH Looker System Activity Detection Queries
-- Vendor: looker | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-bulk-queries
-- Detect bulk query activity
SELECT user_id, COUNT(*) as query_count
FROM history
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 100;
-- HTH Guide Excerpt: end db-detect-bulk-queries

-- HTH Guide Excerpt: begin db-detect-unusual-access
-- Detect unusual data access
SELECT user_id, look_id, dashboard_id
FROM history
WHERE source = 'api'
  AND created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours';
-- HTH Guide Excerpt: end db-detect-unusual-access
