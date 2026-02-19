-- =============================================================================
-- HTH Snowflake Control 3.1: Restrict OAuth Token Scope and Lifetime
-- Profile: L1 | NIST: IA-5(13)
-- https://howtoharden.com/guides/snowflake/#31-restrict-oauth-token-scope-and-lifetime
-- =============================================================================

-- HTH Guide Excerpt: begin db-audit-security-integrations
-- List all security integrations
SHOW SECURITY INTEGRATIONS;

-- Describe OAuth integration details
DESC SECURITY INTEGRATION tableau_oauth;
-- HTH Guide Excerpt: end db-audit-security-integrations
