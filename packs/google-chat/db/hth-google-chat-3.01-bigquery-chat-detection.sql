-- =============================================================================
-- HTH Google Chat BigQuery Detection Queries
-- Vendor: google-chat | Section: 3.1 (Audit Logging & Content Reporting)
-- Requires: Google Workspace activity logs exported to BigQuery.
--           The export writes ONE `activity` table for all applications; the
--           dataset name is chosen by the admin at export setup time, so
--           substitute your own `project.dataset` below.
--           Top-level columns used here (`time_usec`, `email`, `event_name`)
--           are flat, not nested. Chat event names verified against the
--           Admin SDK Reports API Chat activity-events appendix.
-- Note:     Workspace aligns the BigQuery partition boundary to Pacific Time
--           rather than UTC, so `_PARTITIONTIME` is used only for partition
--           pruning and `TIMESTAMP_MICROS(time_usec)` bounds the real window.
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-chat-attachment-exfil
-- Surface users uploading an unusually high volume of Chat attachments
-- (potential data exfiltration through Google Chat).
SELECT
  email,
  COUNT(*) AS attachments_uploaded
FROM `project.dataset.activity`
WHERE event_name = 'attachment_upload'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY email
HAVING attachments_uploaded > 50
ORDER BY attachments_uploaded DESC;
-- HTH Guide Excerpt: end db-detect-chat-attachment-exfil

-- HTH Guide Excerpt: begin db-detect-chat-space-creation
-- Track Google Chat space (room) creation to spot rogue or external spaces.
SELECT
  email,
  COUNT(*) AS spaces_created
FROM `project.dataset.activity`
WHERE event_name = 'room_created'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY email
ORDER BY spaces_created DESC;
-- HTH Guide Excerpt: end db-detect-chat-space-creation
