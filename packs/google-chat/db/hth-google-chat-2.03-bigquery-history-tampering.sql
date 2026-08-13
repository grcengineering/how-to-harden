-- =============================================================================
-- HTH Google Chat Control 2.3: Enforce Google Chat History & Retention
-- Profile Level: L2 (Walk)
-- Frameworks: CIS Controls 8.2/8.10 | NIST 800-53 AU-2, AU-9
-- CISA SCuBA: GWS.CHAT.1.1v1, GWS.CHAT.1.2v1, GWS.CHAT.3.1v1
-- Guide: https://howtoharden.com/guides/google-chat/#23-enforce-google-chat-history--retention
--
-- Requires: Google Workspace activity logs exported to BigQuery (dataset name is
--           admin-chosen; substitute your own `project.dataset`).
--           Flat top-level columns only: time_usec, email, event_name, ip_address.
-- Note:     Workspace aligns the BigQuery partition boundary to Pacific Time, so
--           `_PARTITIONTIME` prunes partitions and `TIMESTAMP_MICROS(time_usec)`
--           bounds the real window.
-- Events:   Verified against the Admin SDK Reports API Chat activity-events
--           appendix: message_deleted, message_edited, room_deleted, room_left,
--           remove_room_member.
--
-- WHY THIS EXISTS: control 2.3 makes history durable. These queries detect the
-- behaviour that erodes it anyway — deletion and editing of content that history
-- was supposed to preserve (MITRE ATT&CK T1562.001, Impair Defenses).
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-chat-message-deletion-spike
-- Bulk message deletion is the Chat analogue of clearing shell history. A user
-- deleting far more than their own baseline is an evidence-destruction signal,
-- and is exactly what an insider does before or after exfiltration.
SELECT
  email AS actor,
  COUNT(*) AS messages_deleted,
  MIN(TIMESTAMP_MICROS(time_usec)) AS first_deletion,
  MAX(TIMESTAMP_MICROS(time_usec)) AS last_deletion,
  COUNT(DISTINCT ip_address) AS distinct_source_ips
FROM `project.dataset.activity`
WHERE event_name = 'message_deleted'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor
HAVING messages_deleted > 25
ORDER BY messages_deleted DESC;
-- HTH Guide Excerpt: end db-detect-chat-message-deletion-spike

-- HTH Guide Excerpt: begin db-detect-chat-space-deletion
-- Deleting a space is a cascading delete: its messages and memberships go with
-- it. Every occurrence deserves an owner and a reason, so this is deliberately
-- unfiltered rather than thresholded.
SELECT
  TIMESTAMP_MICROS(time_usec) AS event_time,
  email AS actor,
  event_name,
  ip_address
FROM `project.dataset.activity`
WHERE event_name IN ('room_deleted', 'message_edited')
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
ORDER BY event_time DESC;
-- HTH Guide Excerpt: end db-detect-chat-space-deletion

-- HTH Guide Excerpt: begin db-detect-chat-membership-churn
-- Members being removed in bulk can precede a space deletion, or quietly cut
-- witnesses out of a conversation before it continues. Pair with the bulk-add
-- detection in the 3.1 pack to see both directions of membership churn.
SELECT
  email AS actor,
  COUNT(*) AS members_removed,
  COUNT(DISTINCT DATE(TIMESTAMP_MICROS(time_usec))) AS active_days
FROM `project.dataset.activity`
WHERE event_name = 'remove_room_member'
  AND _PARTITIONTIME >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND TIMESTAMP_MICROS(time_usec) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY actor
HAVING members_removed > 25
ORDER BY members_removed DESC;
-- HTH Guide Excerpt: end db-detect-chat-membership-churn
