-- =============================================================================
-- HTH Snowflake Control 3.2: Configure External OAuth Integration
-- Profile: L2 | NIST: IA-2(1)
-- =============================================================================

-- HTH Guide Excerpt: begin db-configure-external-oauth
-- Create External OAuth integration with Okta
CREATE OR REPLACE SECURITY INTEGRATION okta_oauth
    TYPE = EXTERNAL_OAUTH
    ENABLED = TRUE
    EXTERNAL_OAUTH_TYPE = OKTA
    EXTERNAL_OAUTH_ISSUER = 'https://your-org.okta.com/oauth2/default'
    EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://your-org.okta.com/oauth2/default/v1/keys'
    EXTERNAL_OAUTH_AUDIENCE_LIST = ('your-snowflake-account')
    EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'sub'
    EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME';

-- For Azure AD
CREATE OR REPLACE SECURITY INTEGRATION azure_ad_oauth
    TYPE = EXTERNAL_OAUTH
    ENABLED = TRUE
    EXTERNAL_OAUTH_TYPE = AZURE
    EXTERNAL_OAUTH_ISSUER = 'https://login.microsoftonline.com/{tenant-id}/v2.0'
    EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys'
    EXTERNAL_OAUTH_AUDIENCE_LIST = ('your-snowflake-account');
-- HTH Guide Excerpt: end db-configure-external-oauth
