# =============================================================================
# HTH Auth0 Control 3.1: Restrict Dashboard Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6(1) | CIS 5.4
# Source: https://howtoharden.com/guides/auth0/#31-restrict-dashboard-admin-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_tenant" "hardened" {
  friendly_name       = var.tenant_name
  session_lifetime    = 8
  idle_session_lifetime = 1

  flags {
    disable_clickjack_protection_headers  = false
    enable_public_signup_user_exists_error = false
    revoke_refresh_token_grant            = true
    enable_sso                            = true
  }

  session_cookie {
    mode = "non-persistent"
  }
}
# HTH Guide Excerpt: end terraform
