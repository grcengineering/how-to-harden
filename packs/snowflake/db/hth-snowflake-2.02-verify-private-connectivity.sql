-- =============================================================================
-- HTH Snowflake Control 2.2: Enable Private Connectivity (PrivateLink)
-- Profile: L2 | NIST: SC-7
-- https://howtoharden.com/guides/snowflake/#22-enable-private-connectivity-privatelinkprivate-service-connect
-- =============================================================================

-- HTH Guide Excerpt: begin db-verify-private-connectivity
-- Verify private connectivity configuration
SELECT SYSTEM$GET_PRIVATELINK_CONFIG();
-- HTH Guide Excerpt: end db-verify-private-connectivity
