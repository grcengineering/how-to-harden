-- =============================================================================
-- HTH Snowflake Control 2.1: Implement Network Policies
-- Profile: L1 | NIST: AC-3, SC-7
-- https://howtoharden.com/guides/snowflake/#21-implement-network-policies
-- =============================================================================

-- HTH Guide Excerpt: begin db-apply-network-policy
-- Apply network policy to account (affects all users)
ALTER ACCOUNT SET NETWORK_POLICY = corporate_access;

-- Or apply to specific users only
ALTER USER external_partner SET NETWORK_POLICY = partner_network_policy;
-- HTH Guide Excerpt: end db-apply-network-policy

-- HTH Guide Excerpt: begin db-validate-network-policy
-- Test from allowed IP - should succeed
SELECT CURRENT_USER();

-- View network policy assignments
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN USER svc_tableau;
-- HTH Guide Excerpt: end db-validate-network-policy
