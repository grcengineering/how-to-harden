# =============================================================================
# HTH Snowflake Control 3.1: Restrict OAuth Token Scope and Lifetime
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(13)
# Source: https://howtoharden.com/guides/snowflake/#31-restrict-oauth-token-scope-and-lifetime
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Snowflake OAuth security integration with restricted scopes
resource "snowflake_security_integration" "oauth_restricted" {
  name    = "HTH_OAUTH_RESTRICTED"
  type    = "OAUTH"
  comment = "HTH: OAuth integration with restricted scopes and blocked admin roles (Control 3.1)"

  oauth_client                       = "CUSTOM"
  oauth_client_type                  = "CONFIDENTIAL"
  oauth_redirect_uri                 = var.oauth_redirect_uri
  oauth_issue_refresh_tokens         = true
  oauth_refresh_token_validity       = var.oauth_refresh_token_validity
  oauth_enforce_pkce                 = "OPTIONAL"

  # Block privileged roles from OAuth access
  blocked_roles_list = [
    "ACCOUNTADMIN",
    "SECURITYADMIN",
    "ORGADMIN",
  ]

  enabled = true
}

# External OAuth integration (L2) for IdP-issued tokens
resource "snowflake_security_integration" "external_oauth" {
  count = var.profile_level >= 2 ? 1 : 0

  name    = "HTH_EXTERNAL_OAUTH"
  type    = "EXTERNAL_OAUTH"
  comment = "HTH: External OAuth with IdP-issued tokens (Control 3.2)"

  external_oauth_type               = var.external_oauth_type
  external_oauth_issuer             = var.external_oauth_issuer
  external_oauth_token_user_mapping_claim = ["sub"]
  external_oauth_snowflake_user_mapping_attribute = "login_name"
  external_oauth_jws_keys_url       = var.external_oauth_jws_keys_url

  blocked_roles_list = [
    "ACCOUNTADMIN",
    "SECURITYADMIN",
    "ORGADMIN",
  ]

  enabled = true
}
# HTH Guide Excerpt: end terraform
