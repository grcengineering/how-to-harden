-- =============================================================================
-- HTH Mailchimp Detection & Monitoring Queries
-- Vendor: mailchimp | Section: 4.1
-- =============================================================================

-- HTH Guide Excerpt: begin db-detect-anomalies
-- Detect bulk exports
SELECT user_email, export_type, record_count
FROM mailchimp_activity
WHERE action = 'export'
  AND record_count > 1000
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect suspicious campaign creation
SELECT user_email, campaign_name, audience_size
FROM campaign_log
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND audience_size > 10000;
-- HTH Guide Excerpt: end db-detect-anomalies
