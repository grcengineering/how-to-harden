# =============================================================================
# HTH Ping Identity Control 3.1: Configure Secure OAuth Settings
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(13), SC-23
# Source: https://howtoharden.com/guides/ping-identity/#31-configure-secure-oauth-settings
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Custom resource server (API) with restricted scopes
resource "pingone_resource" "hardened_api" {
  environment_id = var.pingone_environment_id
  name           = "HTH Hardened API"
  description    = "API resource with scoped access and short token lifetimes"

  audience                      = "https://api.example.com"
  access_token_validity_seconds = var.access_token_lifetime_seconds
}

# Define granular scopes for the API resource
resource "pingone_resource_scope" "read" {
  environment_id = var.pingone_environment_id
  resource_id    = pingone_resource.hardened_api.id
  name           = "read"
  description    = "Read-only access to API resources"
}

resource "pingone_resource_scope" "write" {
  environment_id = var.pingone_environment_id
  resource_id    = pingone_resource.hardened_api.id
  name           = "write"
  description    = "Write access to API resources"
}

# OIDC application with hardened OAuth settings
resource "pingone_application" "hardened_oidc" {
  environment_id = var.pingone_environment_id
  name           = "HTH Hardened OIDC Application"
  enabled        = true

  oidc_options {
    type                        = "WEB_APP"
    grant_types                 = ["AUTHORIZATION_CODE", "REFRESH_TOKEN"]
    response_types              = ["CODE"]
    token_endpoint_auth_method  = "CLIENT_SECRET_POST"
    redirect_uris               = ["https://app.example.com/callback"]
    post_logout_redirect_uris   = ["https://app.example.com/logout"]

    # Enforce PKCE with S256
    pkce_enforcement = "S256_REQUIRED"

    # Token lifetimes
    refresh_token_duration                   = var.refresh_token_lifetime_seconds
    refresh_token_rolling_duration           = var.refresh_token_lifetime_seconds
    refresh_token_rolling_grace_period_duration = 0
  }
}

# L2+: Tighten refresh token lifetime to 24 hours
resource "pingone_application" "hardened_oidc_l2" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH Hardened OIDC Application (L2)"
  enabled        = true

  oidc_options {
    type                        = "WEB_APP"
    grant_types                 = ["AUTHORIZATION_CODE", "REFRESH_TOKEN"]
    response_types              = ["CODE"]
    token_endpoint_auth_method  = "CLIENT_SECRET_POST"
    redirect_uris               = ["https://app.example.com/callback"]
    post_logout_redirect_uris   = ["https://app.example.com/logout"]

    pkce_enforcement = "S256_REQUIRED"

    # L2: Reduced refresh token lifetime (24 hours)
    refresh_token_duration                   = 86400
    refresh_token_rolling_duration           = 86400
    refresh_token_rolling_grace_period_duration = 0
  }
}

# L3+: Disable refresh tokens entirely for maximum security
resource "pingone_application" "hardened_oidc_l3" {
  count = var.profile_level >= 3 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH Hardened OIDC Application (L3)"
  enabled        = true

  oidc_options {
    type                        = "WEB_APP"
    grant_types                 = ["AUTHORIZATION_CODE"]
    response_types              = ["CODE"]
    token_endpoint_auth_method  = "CLIENT_SECRET_POST"
    redirect_uris               = ["https://app.example.com/callback"]
    post_logout_redirect_uris   = ["https://app.example.com/logout"]

    pkce_enforcement = "S256_REQUIRED"

    # L3: No refresh tokens -- force re-authentication
    refresh_token_duration         = 0
    refresh_token_rolling_duration = 0
  }
}
# HTH Guide Excerpt: end terraform
