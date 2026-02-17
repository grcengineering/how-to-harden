# =============================================================================
# HTH Cloudflare Control 2.2: Require WARP for Application Access
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-2(11) | CIS 4.1, 6.4
# Source: https://howtoharden.com/guides/cloudflare/#22-require-warp-for-application-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_device_posture_rule" "warp_connected" {
  account_id  = var.cloudflare_account_id
  name        = "Require WARP Connected"
  type        = "warp"
  description = "Ensure device is running WARP client"

  match = [{
    platform = "windows"
  }, {
    platform = "mac"
  }, {
    platform = "linux"
  }]
}

resource "cloudflare_zero_trust_access_policy" "require_warp" {
  account_id = var.cloudflare_account_id
  name       = "Require WARP for application access"
  decision   = "allow"

  include = [{
    email_domain = {
      domain = var.corporate_domain
    }
  }]

  require = [{
    device_posture = {
      integration_uid = cloudflare_zero_trust_device_posture_rule.warp_connected.id
    }
  }]
}
# HTH Guide Excerpt: end terraform
