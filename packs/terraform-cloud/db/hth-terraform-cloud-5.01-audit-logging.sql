-- HTH Terraform Cloud Control 5.01: Audit Logging
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/terraform-cloud/#51-audit-logging

-- HTH Guide Excerpt: begin detection-queries
-- Detect state access
SELECT user, workspace, action
FROM tfc_audit_log
WHERE action = 'state_version.read'
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect variable changes
SELECT user, workspace, variable_name
FROM tfc_audit_log
WHERE action LIKE '%variable%'
  AND timestamp > NOW() - INTERVAL '7 days';
-- HTH Guide Excerpt: end detection-queries
