# =============================================================================
# HTH Cloudflare Control 2.2: Require WARP for Application Access
# Profile Level: L2 (Walk)
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

# The policy enforces only where an application references it
resource "cloudflare_zero_trust_access_application" "warp_required_app" {
  account_id       = var.cloudflare_account_id
  name             = "WARP-Required Application"
  domain           = var.sensitive_app_domain
  type             = "self_hosted"
  session_duration = "8h"

  policies = [{
    id         = cloudflare_zero_trust_access_policy.require_warp.id
    precedence = 1
  }]
}
# HTH Guide Excerpt: end terraform
