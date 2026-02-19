-- HTH Ping Identity Control 5.01: Configure Comprehensive Audit Logging
-- Profile: L1 | NIST: AU-2, AU-3, AU-6
-- https://howtoharden.com/guides/ping-identity/#51-configure-comprehensive-audit-logging

-- HTH Guide Excerpt: begin detection-queries
-- Detect potential credential stuffing
SELECT ip_address, COUNT(*) as attempts
FROM authentication_events
WHERE result = 'FAILED'
  AND timestamp > NOW() - INTERVAL '5 minutes'
GROUP BY ip_address
HAVING COUNT(*) > 50;

-- Detect privilege escalation
SELECT actor_id, target_user, new_role
FROM admin_events
WHERE event_type = 'ROLE_ASSIGNED'
  AND new_role IN ('Organization Admin', 'Environment Admin')
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect unusual federation patterns
SELECT user_id, application_name, COUNT(*) as access_count
FROM federation_events
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id, application_name
HAVING COUNT(*) > 100;
-- HTH Guide Excerpt: end detection-queries
