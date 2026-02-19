-- =============================================================================
-- HTH Snowflake Control 4.3: Restrict Data Sharing
-- Profile: L1 | NIST: AC-21
-- https://howtoharden.com/guides/snowflake/#43-restrict-data-sharing
-- =============================================================================

-- HTH Guide Excerpt: begin db-audit-data-shares
-- Audit existing shares
SHOW SHARES;

-- Review who has access
SHOW GRANTS ON SHARE customer_data_share;

-- Remove access
REVOKE USAGE ON DATABASE customers FROM SHARE customer_data_share;
-- HTH Guide Excerpt: end db-audit-data-shares
