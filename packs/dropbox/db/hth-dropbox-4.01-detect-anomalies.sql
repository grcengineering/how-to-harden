-- =============================================================================
-- HTH Dropbox Detection & Monitoring Queries
-- Vendor: dropbox | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk downloads
SELECT user_email, COUNT(*) as download_count
FROM dropbox_activity
WHERE action = 'file_download'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 100;

-- Detect external sharing
SELECT user_email, shared_with, file_path
FROM dropbox_activity
WHERE action = 'share_link_create'
  AND is_external = true
  AND timestamp > NOW() - INTERVAL '24 hours';
-- HTH Guide Excerpt: end db-detect-anomalies
