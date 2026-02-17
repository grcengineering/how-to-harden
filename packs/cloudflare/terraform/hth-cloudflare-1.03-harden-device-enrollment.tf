# =============================================================================
# HTH Cloudflare Control 1.3: Harden Device Enrollment
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-2 | CIS 1.4, 5.3
# Source: https://howtoharden.com/guides/cloudflare/#13-harden-device-enrollment
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_access_application" "warp_enrollment" {
  account_id       = var.cloudflare_account_id
  name             = "Device Enrollment"
  type             = "warp"
  session_duration = "24h"

  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.corporate_idp.id]
  auto_redirect_to_identity = true
}

resource "cloudflare_zero_trust_access_policy" "device_enrollment_policy" {
  account_id = var.cloudflare_account_id
  name       = "Restrict device enrollment to corporate users"
  decision   = "allow"

  include = [{
    email_domain = {
      domain = var.corporate_domain
    }
  }]

  require = [{
    auth_method = {
      auth_method = "mfa"
    }
  }]
}
# HTH Guide Excerpt: end terraform
