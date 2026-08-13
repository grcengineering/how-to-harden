-- =============================================================================
-- HTH Google Chat Control 1.1: Restrict & Allowlist Google Chat Apps
-- Profile Level: L1 (Crawl)
-- Frameworks: CIS Controls 2.5/2.7 | NIST 800-53 AC-3, CM-7
-- Guide: https://howtoharden.com/guides/google-chat/#11-restrict--allowlist-google-chat-apps
--
-- Requires: Google Workspace activity logs exported to BigQuery.
--           The export creates ONE dataset containing an `activity` table (and a
--           `usage` table); the dataset name is chosen by the admin at export
--           setup time, so substitute your own `project.dataset` below.
--           Columns used here (`time_usec`, `email`, `event_name`, `record_type`,
--           `ip_address`) are FLAT top-level columns, matching the form used in
--           Google's own example queries.
-- Note:     Workspace overrides BigQuery's default UTC partition boundary to
--           align partitions with Pacific Time, so `_PARTITIONTIME` is used only
--           for partition pruning and `TIMESTAMP_MICROS(time_usec)` bounds the
--           real analysis window.
-- Events:   Verified against the Admin SDK Reports API Chat activity-events
--           appendix (developers.google.com/workspace/admin/reports/v1/appendix/
--           activity/chat): app_added, app_removed, app_invoked.
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-chat-app-installs
-- Chat app installations. Control 1.1 restricts WHO may install apps; this
-- shows whether the restriction is actually holding, and surfaces installs that
-- predate it. Investigate any actor outside the approved Marketplace workflow.
SELECT
  TIMESTAMP_MICROS(time_usec) AS event_time,
  email AS actor,
  event_name,
  ip_address
FROM `project.dataset.activity`
WHERE event_name IN ('app_added', 'app_removed')
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
ORDER BY event_time DESC;
-- HTH Guide Excerpt: end db-detect-chat-app-installs

-- HTH Guide Excerpt: begin db-detect-chat-app-invocation-spike
-- Chat apps run with delegated access to conversation content, so an app being
-- invoked far more than its peers is worth a look — either it is doing more than
-- its business purpose requires, or it is being driven programmatically.
SELECT
  email AS actor,
  COUNT(*) AS invocations,
  COUNT(DISTINCT DATE(TIMESTAMP_MICROS(time_usec))) AS active_days,
  COUNT(DISTINCT ip_address) AS distinct_source_ips
FROM `project.dataset.activity`
WHERE event_name = 'app_invoked'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor
HAVING invocations > 500
ORDER BY invocations DESC;
-- HTH Guide Excerpt: end db-detect-chat-app-invocation-spike

-- HTH Guide Excerpt: begin db-discover-chat-nested-schema
-- Event PARAMETERS (actor_type, conversation_ownership, conversation_type, and
-- the attachment_* fields) are documented in the Reports API appendix, but their
-- BigQuery column paths are not published. Rather than guessing a path, read the
-- schema your own export actually produced, then extend these queries from it.
SELECT column_name, data_type
FROM `project.dataset.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'activity'
  AND LOWER(column_name) LIKE '%chat%'
ORDER BY column_name;
-- HTH Guide Excerpt: end db-discover-chat-nested-schema
