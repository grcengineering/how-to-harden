-- =============================================================================
-- HTH Cursor Control 7.1: Cursor Usage Logging Monitoring Queries
-- Profile: L2 | NIST: AU-2
-- https://howtoharden.com/guides/cursor/#71-enable-cursor-usage-logging
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-excessive-usage
-- Detect excessive AI usage (flag heavy users with >1000 requests/day)
SELECT user, count(*) as ai_requests, date
FROM cursor_logs
WHERE event_type = 'ai.completion'
GROUP BY user, date
HAVING count(*) > 1000;
-- HTH Guide Excerpt: end db-detect-excessive-usage

-- HTH Guide Excerpt: begin db-detect-privacy-bypass
-- Detect privacy mode bypass (cloud AI requests in confidential workspaces)
SELECT user, workspace, timestamp
FROM cursor_logs
WHERE event_type = 'ai.request'
  AND privacy_mode = false
  AND workspace LIKE '%confidential%';
-- HTH Guide Excerpt: end db-detect-privacy-bypass
