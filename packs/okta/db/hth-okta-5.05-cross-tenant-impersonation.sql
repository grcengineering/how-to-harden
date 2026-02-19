-- HTH Guide Excerpt: begin db-siem-idp-created
-- Alert: New Identity Provider Created (CRITICAL)
SELECT actor.displayName, actor.alternateId, target[0].displayName,
       target[0].type, client.ipAddress, published
FROM okta_system_log
WHERE eventType IN (
  'system.idp.lifecycle.create',
  'system.idp.lifecycle.activate'
)
-- HTH Guide Excerpt: end db-siem-idp-created

-- HTH Guide Excerpt: begin db-siem-routing-rule-modified
-- Alert: Routing Rule Modified (HIGH)
SELECT actor.displayName, target[0].displayName, published
FROM okta_system_log
WHERE eventType IN ('policy.lifecycle.create', 'policy.lifecycle.update')
  AND debugContext.debugData.policyType = 'IDP_DISCOVERY'
-- HTH Guide Excerpt: end db-siem-routing-rule-modified
