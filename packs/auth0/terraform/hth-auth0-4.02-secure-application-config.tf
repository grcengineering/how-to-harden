# =============================================================================
# HTH Auth0 Control 4.2: Secure Application Configurations
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7 | CIS 4.1
# Source: https://howtoharden.com/guides/auth0/#42-secure-application-configurations
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_client" "secure_app" {
  name     = var.app_name
  app_type = "regular_web"

  oidc_conformant = true

  jwt_configuration {
    lifetime_in_seconds = 300
    alg                 = "RS256"
  }

  refresh_token {
    rotation_type       = "rotating"
    expiration_type     = "expiring"
    token_lifetime      = 2592000
    idle_token_lifetime = 1296000
    leeway              = 0
  }
}
# HTH Guide Excerpt: end terraform
