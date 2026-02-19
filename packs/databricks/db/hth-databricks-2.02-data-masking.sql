-- =============================================================================
-- HTH Databricks Control 2.2: Configure Data Masking
-- Profile: L2 | NIST: SC-28
-- https://howtoharden.com/guides/databricks/#22-configure-data-masking
-- =============================================================================

-- HTH Guide Excerpt: begin db-create-masking-function
-- Create masking function for SSN
CREATE FUNCTION production.masks.mask_ssn(ssn STRING)
RETURNS STRING
RETURN CASE
    WHEN is_account_group_member('pii_admin') THEN ssn
    ELSE CONCAT('XXX-XX-', RIGHT(ssn, 4))
END;

-- Apply mask to column
ALTER TABLE production.customer_data.customers
ALTER COLUMN ssn SET MASK production.masks.mask_ssn;
-- HTH Guide Excerpt: end db-create-masking-function
