-- HTH Workday Control 5.1: Enable Audit Logging
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/workday/#51-enable-audit-logging

-- HTH Guide Excerpt: begin db-detect-bulk-access
-- Detect bulk data access
SELECT user_id, COUNT(*) as record_count
FROM workday_audit_log
WHERE action = 'View'
  AND object_type IN ('Worker', 'Compensation')
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 100;

-- Detect ISU anomalies
SELECT isu_name, api_endpoint, COUNT(*) as call_count
FROM api_access_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY isu_name, api_endpoint
HAVING COUNT(*) > 1000;

-- Detect sensitive field access
SELECT user_id, field_name, worker_id
FROM field_access_log
WHERE field_name IN ('SSN', 'Bank_Account', 'Salary')
  AND timestamp > NOW() - INTERVAL '24 hours';
-- HTH Guide Excerpt: end db-detect-bulk-access
