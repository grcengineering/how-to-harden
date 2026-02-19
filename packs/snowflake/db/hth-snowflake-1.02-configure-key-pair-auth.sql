-- =============================================================================
-- HTH Snowflake Control 1.2: Configure Key-Pair Authentication
-- Profile: L1 | NIST: IA-5
-- =============================================================================

-- HTH Guide Excerpt: begin db-configure-key-pair
-- Remove password from service account
ALTER USER svc_etl_pipeline
    SET RSA_PUBLIC_KEY = 'MIIBIjANBgkqhki...'
    UNSET PASSWORD;

-- Verify
DESC USER svc_etl_pipeline;
-- HTH Guide Excerpt: end db-configure-key-pair
