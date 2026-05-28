-- =============================================================================
-- HTH Google Workspace BigQuery Detection Queries
-- Vendor: google-workspace | Section: 5.2 (Google Chat)
-- Requires: Chat audit logs exported to BigQuery (see control 5.1).
--           Event names verified against the Admin SDK Reports API chat appendix.
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-chat-attachment-exfil
-- Surface users uploading an unusually high volume of Chat attachments
-- (potential data exfiltration through Google Chat).
SELECT
  actor.email,
  COUNT(*) AS attachments_uploaded
FROM `project.dataset.chat_logs`
WHERE event_name = 'attachment_upload'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor.email
HAVING attachments_uploaded > 50
ORDER BY attachments_uploaded DESC;
-- HTH Guide Excerpt: end db-detect-chat-attachment-exfil

-- HTH Guide Excerpt: begin db-detect-chat-space-creation
-- Track Google Chat space (room) creation to spot rogue or external spaces.
SELECT
  actor.email,
  COUNT(*) AS spaces_created
FROM `project.dataset.chat_logs`
WHERE event_name = 'room_created'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY actor.email
ORDER BY spaces_created DESC;
-- HTH Guide Excerpt: end db-detect-chat-space-creation
