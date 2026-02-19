-- HTH Guide Excerpt: begin db-siem-default-policy-bypass
-- Alert: Authentication via Default Policy (MFA bypass)
SELECT actor.displayName, client.ipAddress, outcome.result, published
FROM okta_system_log
WHERE eventType = 'policy.evaluate_sign_on'
  AND debugContext.debugData.behaviors LIKE '%Default Policy%'
ORDER BY published DESC
-- HTH Guide Excerpt: end db-siem-default-policy-bypass
