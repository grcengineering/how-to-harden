-- =============================================================================
-- HTH Snowflake Control 4.2: Row Access Policy
-- Profile: L2 | NIST: AC-3
-- =============================================================================

-- HTH Guide Excerpt: begin db-row-access-policy
-- Create row access policy
CREATE OR REPLACE ROW ACCESS POLICY region_access AS (region_col VARCHAR)
RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('DATA_ADMIN')
    OR region_col = CURRENT_SESSION()::JSON:region;

-- Apply to table
ALTER TABLE sales ADD ROW ACCESS POLICY region_access ON (region);
-- HTH Guide Excerpt: end db-row-access-policy
