# =============================================================================
# HTH Cloudflare Control 4.3: Configure Split Tunnel Settings
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-7 | CIS 13.5
# Source: https://howtoharden.com/guides/cloudflare/#43-configure-split-tunnel-settings
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_device_default_profile" "split_tunnel" {
  account_id    = var.cloudflare_account_id
  switch_locked = true

  exclude = [{
    address     = "10.0.0.0/8"
    description = "Internal RFC1918"
  }, {
    address     = "172.16.0.0/12"
    description = "Internal RFC1918"
  }, {
    address     = "192.168.0.0/16"
    description = "Internal RFC1918"
  }]
}
# HTH Guide Excerpt: end terraform
