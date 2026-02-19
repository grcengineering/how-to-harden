-- HTH Adobe Marketo Control 4.1: Audit Trail
-- Profile: L1 | NIST: AU-2, AU-3
-- https://howtoharden.com/guides/marketo/#41-audit-trail

-- HTH Guide Excerpt: begin db-detect-bulk-exports
-- Detect bulk lead exports
SELECT user_email, export_type, lead_count
FROM marketo_audit_log
WHERE action = 'EXPORT_LEADS'
  AND lead_count > 10000
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect API abuse
SELECT service_name, endpoint, COUNT(*) as calls
FROM api_usage_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY service_name, endpoint
HAVING COUNT(*) > 1000;
-- HTH Guide Excerpt: end db-detect-bulk-exports
