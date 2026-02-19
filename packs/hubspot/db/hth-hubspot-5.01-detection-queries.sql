-- HTH HubSpot Control 5.1: Enable Audit Logging
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/hubspot/#51-enable-audit-logging

-- HTH Guide Excerpt: begin db-detect-bulk-access
-- Detect bulk contact access
SELECT user_id, COUNT(*) as view_count
FROM hubspot_activity_log
WHERE action = 'contact.view'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 100;

-- Detect API key creation
SELECT *
FROM hubspot_activity_log
WHERE action = 'private_app.created'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect permission changes
SELECT *
FROM hubspot_activity_log
WHERE action LIKE '%permission%'
  AND timestamp > NOW() - INTERVAL '7 days';
-- HTH Guide Excerpt: end db-detect-bulk-access
