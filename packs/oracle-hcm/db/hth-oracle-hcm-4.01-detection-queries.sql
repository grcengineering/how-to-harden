-- HTH Oracle HCM Cloud Control 4.1: Enable Audit Policies
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/oracle-hcm/#41-enable-audit-policies

-- HTH Guide Excerpt: begin db-detect-bulk-access
-- Detect bulk employee data access
SELECT user_name, web_service, COUNT(*) as calls
FROM fusion_audit_log
WHERE module = 'HCM'
  AND operation_type = 'READ'
  AND timestamp > SYSDATE - 1
GROUP BY user_name, web_service
HAVING COUNT(*) > 100;
-- HTH Guide Excerpt: end db-detect-bulk-access
