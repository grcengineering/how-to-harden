-- =============================================================================
-- HTH Snowflake Control 6.2: Tableau Integration Hardening
-- Profile: L1
-- =============================================================================

-- HTH Guide Excerpt: begin db-tableau-integration
-- Create restricted role for Tableau
CREATE ROLE tableau_reader;
GRANT USAGE ON WAREHOUSE bi_warehouse TO ROLE tableau_reader;
GRANT USAGE ON DATABASE analytics TO ROLE tableau_reader;
GRANT USAGE ON ALL SCHEMAS IN DATABASE analytics TO ROLE tableau_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics.dashboards TO ROLE tableau_reader;

-- Create service account
CREATE USER svc_tableau
    DEFAULT_ROLE = tableau_reader
    DEFAULT_WAREHOUSE = bi_warehouse
    RSA_PUBLIC_KEY = 'MIIBIjAN...';

-- Apply network policy
ALTER USER svc_tableau SET NETWORK_POLICY = tableau_only;
-- HTH Guide Excerpt: end db-tableau-integration
