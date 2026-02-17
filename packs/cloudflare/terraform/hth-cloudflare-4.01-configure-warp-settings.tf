# =============================================================================
# HTH Cloudflare Control 4.1: Configure WARP Client Settings
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7, SC-7 | CIS 4.1
# Source: https://howtoharden.com/guides/cloudflare/#41-configure-warp-client-settings
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_device_default_profile" "default" {
  account_id        = var.cloudflare_account_id
  auto_connect      = 0
  captive_portal    = 180
  allow_mode_switch = false
  allow_updates     = true
  tunnel_protocol   = "wireguard"

  service_mode_v2 = {
    mode = "warp"
  }
}
# HTH Guide Excerpt: end terraform
