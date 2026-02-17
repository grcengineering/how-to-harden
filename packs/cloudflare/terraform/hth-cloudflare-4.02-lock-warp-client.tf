# =============================================================================
# HTH Cloudflare Control 4.2: Lock WARP Client
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7 | CIS 4.1
# Source: https://howtoharden.com/guides/cloudflare/#42-lock-warp-client
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_device_default_profile" "locked" {
  account_id        = var.cloudflare_account_id
  switch_locked     = true
  allowed_to_leave  = false
  allow_mode_switch = false
  auto_connect      = 0
}
# HTH Guide Excerpt: end terraform
