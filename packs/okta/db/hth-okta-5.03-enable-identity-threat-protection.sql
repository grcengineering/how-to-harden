-- HTH Guide Excerpt: begin db-siem-itp-high-risk
SELECT actor.displayName, client.ipAddress, outcome.result,
       debugContext.debugData.riskLevel, debugContext.debugData.riskReasons
FROM okta_system_log
WHERE eventType = 'security.threat.detected'
  AND debugContext.debugData.riskLevel IN ('HIGH', 'CRITICAL')
ORDER BY published DESC
-- HTH Guide Excerpt: end db-siem-itp-high-risk
