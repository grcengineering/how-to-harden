-- =============================================================================
-- HTH Box Detection & Monitoring Queries
-- Vendor: box | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk downloads
SELECT user_email, COUNT(*) as download_count
FROM box_events
WHERE event_type = 'DOWNLOAD'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_email
HAVING COUNT(*) > 50;
-- HTH Guide Excerpt: end db-detect-anomalies
