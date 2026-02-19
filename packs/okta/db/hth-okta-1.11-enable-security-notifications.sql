-- HTH Guide Excerpt: begin db-siem-suspicious-activity-report
-- HIGH PRIORITY: User reported suspicious activity
SELECT actor.displayName, actor.alternateId, client.ipAddress,
       client.geographicalContext.city, client.geographicalContext.country,
       outcome.result, published
FROM okta_system_log
WHERE eventType = 'user.account.report_suspicious_activity_by_enduser'
ORDER BY published DESC
-- HTH Guide Excerpt: end db-siem-suspicious-activity-report

-- HTH Guide Excerpt: begin db-siem-authenticator-enrolled
-- MEDIUM PRIORITY: Authenticator enrolled from unrecognized location
-- (Correlate with new sign-on notifications)
SELECT actor.displayName, target.displayName AS authenticator_type,
       client.ipAddress, client.userAgent.rawUserAgent, published
FROM okta_system_log
WHERE eventType IN (
  'user.mfa.factor.activate',
  'user.mfa.factor.enroll',
  'system.mfa.factor.activate'
)
ORDER BY published DESC
-- HTH Guide Excerpt: end db-siem-authenticator-enrolled
