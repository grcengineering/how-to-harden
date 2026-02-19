-- =============================================================================
-- HTH Tableau Admin Insights Detection Queries
-- Vendor: tableau | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-bulk-downloads
-- Detect bulk data downloads
SELECT user_name, workbook_name, download_count
FROM admin_insights
WHERE action = 'Download'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY user_name, workbook_name
HAVING download_count > 10;
-- HTH Guide Excerpt: end db-detect-bulk-downloads

-- HTH Guide Excerpt: begin db-detect-unusual-access
-- Detect unusual access patterns
SELECT user_name, site_role, view_count
FROM traffic_to_views
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_name, site_role
HAVING view_count > 100;
-- HTH Guide Excerpt: end db-detect-unusual-access
