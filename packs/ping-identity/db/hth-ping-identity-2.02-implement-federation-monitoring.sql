-- HTH Ping Identity Control 2.02: Implement Federation Monitoring
-- Profile: L1 | NIST: AU-6, SI-4
-- https://howtoharden.com/guides/ping-identity/#22-implement-federation-monitoring

-- HTH Guide Excerpt: begin federation-detection-queries
-- Detect unusual federation token issuance
SELECT application_name, COUNT(*) as token_count
FROM federation_events
WHERE event_type = 'TOKEN_ISSUED'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY application_name
HAVING COUNT(*) > 100;

-- Detect new user federation patterns
SELECT user_id, application_name, first_access
FROM (
  SELECT user_id, application_name,
         MIN(timestamp) as first_access
  FROM federation_events
  WHERE timestamp > NOW() - INTERVAL '24 hours'
  GROUP BY user_id, application_name
) new_access
WHERE first_access > NOW() - INTERVAL '24 hours';

-- Detect after-hours admin authentication
SELECT user_id, application_name, timestamp
FROM federation_events
WHERE application_name = 'PingOne Admin Console'
  AND (EXTRACT(HOUR FROM timestamp) < 6
       OR EXTRACT(HOUR FROM timestamp) > 20);
-- HTH Guide Excerpt: end federation-detection-queries
