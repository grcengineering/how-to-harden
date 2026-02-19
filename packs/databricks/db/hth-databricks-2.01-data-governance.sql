-- =============================================================================
-- HTH Databricks Control 2.1: Implement Data Governance
-- Profile: L1 | NIST: AC-3
-- https://howtoharden.com/guides/databricks/#21-implement-data-governance
-- =============================================================================

-- HTH Guide Excerpt: begin db-create-catalog-structure
-- Create catalogs by environment
CREATE CATALOG IF NOT EXISTS production;
CREATE CATALOG IF NOT EXISTS staging;
CREATE CATALOG IF NOT EXISTS development;

-- Create schemas by domain
CREATE SCHEMA IF NOT EXISTS production.finance;
CREATE SCHEMA IF NOT EXISTS production.customer_data;
CREATE SCHEMA IF NOT EXISTS production.ml_features;
-- HTH Guide Excerpt: end db-create-catalog-structure

-- HTH Guide Excerpt: begin db-configure-permissions
-- Grant specific permissions
GRANT USE CATALOG ON CATALOG production TO `data_analysts`;
GRANT USE SCHEMA ON SCHEMA production.finance TO `finance_team`;
GRANT SELECT ON TABLE production.finance.transactions TO `finance_team`;

-- Restrict sensitive tables
DENY SELECT ON TABLE production.customer_data.pii TO `general_users`;
-- HTH Guide Excerpt: end db-configure-permissions

-- HTH Guide Excerpt: begin db-column-level-security
-- Create row filter function
CREATE FUNCTION production.filters.region_filter()
RETURNS STRING
RETURN CASE
    WHEN is_account_group_member('us_team') THEN 'region = "US"'
    WHEN is_account_group_member('eu_team') THEN 'region = "EU"'
    ELSE 'FALSE'
END;

-- Apply to table
ALTER TABLE production.customer_data.orders
SET ROW FILTER production.filters.region_filter ON (region);
-- HTH Guide Excerpt: end db-column-level-security
