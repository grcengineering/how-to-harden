-- HTH Guide Excerpt: begin db-siem-impossible-travel
-- Detect impossible travel
SELECT user, sourceIp, geo_country, timestamp
FROM okta_logs
WHERE eventType = 'user.authentication.sso'
  AND geo_country_change_within_1hr = true
-- HTH Guide Excerpt: end db-siem-impossible-travel

-- HTH Guide Excerpt: begin db-siem-brute-force
-- Detect brute force
SELECT user, count(*) as attempts
FROM okta_logs
WHERE eventType = 'user.authentication.failed'
  AND timestamp > now() - interval '5 minutes'
GROUP BY user
HAVING count(*) > 10
-- HTH Guide Excerpt: end db-siem-brute-force

-- HTH Guide Excerpt: begin db-siem-admin-role-changes
-- Detect admin role changes
SELECT actor, target, eventType, timestamp
FROM okta_logs
WHERE eventType LIKE 'system.role%'
  OR eventType LIKE 'group.user_membership%admin%'
-- HTH Guide Excerpt: end db-siem-admin-role-changes
