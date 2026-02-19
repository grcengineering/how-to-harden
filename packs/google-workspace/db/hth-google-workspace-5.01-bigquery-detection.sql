-- =============================================================================
-- HTH Google Workspace BigQuery Detection Queries
-- Vendor: google-workspace | Section: 5.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-failed-logins
-- Find failed login attempts by user
SELECT
  actor.email,
  COUNT(*) as failed_attempts
FROM `project.dataset.login_logs`
WHERE event_name = 'login_failure'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor.email
HAVING failed_attempts > 10
ORDER BY failed_attempts DESC;
-- HTH Guide Excerpt: end db-detect-failed-logins

-- HTH Guide Excerpt: begin db-detect-external-sharing
-- Find external file sharing
SELECT
  actor.email,
  doc_title,
  target_user
FROM `project.dataset.drive_logs`
WHERE event_name = 'change_user_access'
  AND target_user NOT LIKE '%@yourdomain.com'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR);
-- HTH Guide Excerpt: end db-detect-external-sharing
