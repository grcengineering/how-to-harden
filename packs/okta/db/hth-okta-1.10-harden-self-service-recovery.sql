-- HTH Guide Excerpt: begin db-siem-recovery-non-corporate-ip
-- Alert: Password recovery from non-corporate IP
SELECT actor.displayName, client.ipAddress, client.geographicalContext.city,
       client.geographicalContext.country, outcome.result, published
FROM okta_system_log
WHERE eventType IN ('user.account.reset_password', 'user.credential.forgot_password')
  AND client.ipAddress NOT IN (SELECT ip FROM corporate_ip_ranges)
ORDER BY published DESC
-- HTH Guide Excerpt: end db-siem-recovery-non-corporate-ip

-- HTH Guide Excerpt: begin db-siem-recovery-weak-factor
-- Alert: SMS/Voice recovery attempt (should not occur after hardening)
SELECT actor.displayName, client.ipAddress, outcome.result, published
FROM okta_system_log
WHERE eventType = 'user.account.reset_password'
  AND debugContext.debugData.factor IN ('SMS', 'CALL', 'QUESTION')
ORDER BY published DESC
-- HTH Guide Excerpt: end db-siem-recovery-weak-factor
