-- HTH Adobe Marketo Control 4.2: Integration Monitoring
-- Profile: L2
-- https://howtoharden.com/guides/marketo/#42-integration-monitoring

-- HTH Guide Excerpt: begin db-detect-new-services
-- Detect new LaunchPoint services
SELECT service_name, created_by, created_date
FROM launchpoint_services
WHERE created_date > NOW() - INTERVAL '7 days';

-- Detect email template changes
SELECT asset_name, modified_by, modification_type
FROM audit_trail
WHERE asset_type = 'EMAIL'
  AND modification_type IN ('APPROVE', 'UNAPPROVE')
  AND timestamp > NOW() - INTERVAL '24 hours';
-- HTH Guide Excerpt: end db-detect-new-services
