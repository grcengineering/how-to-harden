# =============================================================================
# HTH Cloudflare Control 1.2: Configure Multi-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1) | CIS 6.5
# Source: https://howtoharden.com/guides/cloudflare/#12-configure-multi-factor-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_access_policy" "require_mfa" {
  account_id = var.cloudflare_account_id
  name       = "Require MFA for all users"
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

  session_duration = "24h"
}
# HTH Guide Excerpt: end terraform
