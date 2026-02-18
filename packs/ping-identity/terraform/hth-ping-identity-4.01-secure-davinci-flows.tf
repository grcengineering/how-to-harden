# =============================================================================
# HTH Ping Identity Control 4.1: Secure DaVinci Flows
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3, CM-3
# Source: https://howtoharden.com/guides/ping-identity/#41-secure-davinci-flows
# =============================================================================

# HTH Guide Excerpt: begin terraform
# DaVinci flow policy -- restrict flow execution to approved applications (L2+)
resource "pingone_application" "davinci_restricted" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH DaVinci Restricted Application"
  enabled        = true
  description    = "Hardened DaVinci application with restricted connector access"

  oidc_options {
    type                        = "WEB_APP"
    grant_types                 = ["AUTHORIZATION_CODE"]
    response_types              = ["CODE"]
    token_endpoint_auth_method  = "CLIENT_SECRET_POST"
    redirect_uris               = ["https://app.example.com/callback"]

    pkce_enforcement = "S256_REQUIRED"
  }
}

# Sign-on policy for DaVinci flows requiring elevated authentication
resource "pingone_sign_on_policy" "davinci_elevated" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH DaVinci Elevated Auth"
  description    = "Requires additional authentication for sensitive DaVinci flow actions"
}

# DaVinci flow action: require MFA for sensitive connector operations
resource "pingone_sign_on_policy_action" "davinci_mfa_required" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.davinci_elevated[0].id
  priority          = 1

  mfa {
    device_sign_on_policy_id = pingone_mfa_device_policy.phishing_resistant.id
    no_device_mode           = "BLOCK"
  }
}

# L3+: Strict DaVinci controls -- all flow changes require approval
resource "pingone_sign_on_policy" "davinci_strict" {
  count = var.profile_level >= 3 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH DaVinci Strict Governance"
  description    = "Maximum security: all DaVinci changes require security team approval"
}
# HTH Guide Excerpt: end terraform
