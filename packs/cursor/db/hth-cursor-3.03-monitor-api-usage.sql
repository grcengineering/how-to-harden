-- =============================================================================
-- HTH Cursor Control 3.3: Monitor API Key Usage and Costs
-- Profile: L2 | NIST: AU-6
-- https://howtoharden.com/guides/cursor/#33-monitor-api-key-usage-and-costs
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-usage-spike
-- Detect unusual API usage spike (3x above average)
-- Requires logging API calls to a cursor_api_logs table
SELECT date, count(*) as api_calls, sum(tokens) as total_tokens
FROM cursor_api_logs
GROUP BY date
HAVING count(*) > (SELECT avg(count) * 3 FROM cursor_api_logs);
-- HTH Guide Excerpt: end db-detect-usage-spike
