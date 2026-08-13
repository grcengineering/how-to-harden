-- =============================================================================
-- HTH Google Chat BigQuery Detection Queries
-- Vendor: google-chat | Section: 3.1 (Audit Logging & Content Reporting)
-- Profile Level: L1 (Crawl)
-- Frameworks: CIS Controls 8.2/8.5 | NIST 800-53 AU-2, AU-6, IR-6
-- CISA SCuBA: GWS.CHAT.5.1v1, GWS.CHAT.5.2v1
-- Guide: https://howtoharden.com/guides/google-chat/#31-enable-google-chat-audit-logging--content-reporting
--
-- Requires: Google Workspace activity logs exported to BigQuery.
--           The export writes ONE `activity` table for all applications; the
--           dataset name is chosen by the admin at export setup time, so
--           substitute your own `project.dataset` below.
--           Top-level columns used here (`time_usec`, `email`, `event_name`,
--           `ip_address`) are flat, not nested. Chat event names verified
--           against the Admin SDK Reports API Chat activity-events appendix.
-- Note:     Workspace aligns the BigQuery partition boundary to Pacific Time
--           rather than UTC, so `_PARTITIONTIME` is used only for partition
--           pruning and `TIMESTAMP_MICROS(time_usec)` bounds the real window.
--
-- SIBLING PACKS (same corpus, different control):
--   1.1 -> hth-google-chat-1.01-bigquery-chat-app-abuse.sql  (Chat app/webhook abuse)
--   2.3 -> hth-google-chat-2.03-bigquery-history-tampering.sql (evidence destruction)
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

-- HTH Guide Excerpt: begin db-detect-chat-message-volume
-- Flag accounts posting Chat messages at an abnormal rate (phishing or
-- malicious-link distribution). A high distinct-source-IP count alongside
-- high volume suggests a compromised account rather than a chatty user.
SELECT
  email,
  COUNT(*) AS messages_posted,
  COUNT(DISTINCT ip_address) AS distinct_source_ips
FROM `project.dataset.activity`
WHERE event_name = 'message_posted'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
GROUP BY email
HAVING messages_posted > 200
ORDER BY messages_posted DESC;
-- HTH Guide Excerpt: end db-detect-chat-message-volume

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

-- HTH Guide Excerpt: begin db-detect-chat-attachment-download
-- The upload query above catches data going INTO Chat; this catches it coming
-- back OUT. A compromised account harvesting an existing space's attachment
-- history generates downloads without ever uploading anything, so a
-- upload-only detection misses the entire read side of exfiltration.
SELECT
  email AS actor,
  COUNT(*) AS attachments_downloaded,
  COUNT(DISTINCT ip_address) AS distinct_source_ips,
  MIN(TIMESTAMP_MICROS(time_usec)) AS window_start,
  MAX(TIMESTAMP_MICROS(time_usec)) AS window_end
FROM `project.dataset.activity`
WHERE event_name = 'attachment_download'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor
HAVING attachments_downloaded > 50
ORDER BY attachments_downloaded DESC;
-- HTH Guide Excerpt: end db-detect-chat-attachment-download

-- HTH Guide Excerpt: begin db-measure-report-queue-health
-- Content reporting (this control) creates a queue; control 3.3 assigns it an
-- owner. This measures whether the queue is actually being worked: reports
-- raised versus reports resolved, and the backlog between them. A queue with
-- reports and no resolutions is a detection control producing no detections.
WITH reports AS (
  SELECT
    DATE(TIMESTAMP_MICROS(time_usec)) AS day,
    COUNTIF(event_name = 'message_reported')        AS reported,
    COUNTIF(event_name = 'message_report_resolved') AS resolved
  FROM `project.dataset.activity`
  WHERE event_name IN ('message_reported', 'message_report_resolved')
    AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
    AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  GROUP BY day
)
SELECT
  day,
  reported,
  resolved,
  reported - resolved AS unresolved_delta,
  SUM(reported - resolved) OVER (ORDER BY day) AS running_backlog
FROM reports
ORDER BY day DESC;
-- HTH Guide Excerpt: end db-measure-report-queue-health

-- HTH Guide Excerpt: begin db-detect-chat-member-adds
-- Surface actors adding space members in bulk (rogue-space population or
-- staging for exfiltration). Triage hits in Admin Console > Chat log events,
-- where the add_room_member entry lists the added target users, to confirm
-- whether the added members are external to your domain.
SELECT
  email,
  COUNT(*) AS members_added
FROM `project.dataset.activity`
WHERE event_name = 'add_room_member'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY email
HAVING members_added > 25
ORDER BY members_added DESC;
-- HTH Guide Excerpt: end db-detect-chat-member-adds
