-- =============================================================================
-- HTH Zoom Control 5.1: Audit Log Detection Queries
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect unusual meeting creation
SELECT user_id, COUNT(*) as meeting_count
FROM zoom_meetings
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 20;

-- Detect recording access anomalies
SELECT user_id, recording_id, access_time
FROM recording_access_log
WHERE user_id NOT IN (SELECT host_id FROM meetings WHERE id = recording_id);
-- HTH Guide Excerpt: end db-detect-anomalies
