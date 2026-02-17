# =============================================================================
# HTH Cloudflare Control 1.1: Configure Identity Provider Integration
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2, IA-8 | CIS 6.3, 12.5
# Source: https://howtoharden.com/guides/cloudflare/#11-configure-identity-provider-integration
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_access_identity_provider" "corporate_idp" {
  account_id = var.cloudflare_account_id
  name       = "Corporate IdP"
  type       = "oidc"

  config = {
    client_id     = var.oidc_client_id
    client_secret = var.oidc_client_secret
    auth_url      = var.oidc_auth_url
    token_url     = var.oidc_token_url
    certs_url     = var.oidc_certs_url
    claims        = ["email_verified", "preferred_username", "groups"]
    scopes        = ["openid", "email", "profile", "groups"]
  }
}
# HTH Guide Excerpt: end terraform
