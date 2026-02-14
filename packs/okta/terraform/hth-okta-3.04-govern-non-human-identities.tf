# =============================================================================
# HTH Okta Control 3.4: Govern Non-Human Identities (NHI)
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.2, NIST AC-6, CM-7
# Source: https://howtoharden.com/guides/okta/#34-govern-non-human-identities
# =============================================================================

# OAuth 2.0 service app using client_credentials with private_key_jwt
resource "okta_app_oauth" "service_automation" {
  label                      = "SVC - Automation API Access"
  type                       = "service"
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  token_endpoint_auth_method = "private_key_jwt"
  pkce_required              = false

  jwks {
    kty = "RSA"
    e   = var.service_app_public_key_e
    n   = var.service_app_public_key_n
  }
}

# Grant minimum-required API scopes to the service app
resource "okta_app_oauth_api_scope" "users_read" {
  app_id = okta_app_oauth.service_automation.id
  issuer = "https://${var.okta_domain}"
  scopes = ["okta.users.read"]
}
