# =============================================================================
# HTH Cloudflare Control 4.2: Lock WARP Client
# Profile Level: L2 (Walk)
# Frameworks: NIST CM-7 | CIS 4.1
# Source: https://howtoharden.com/guides/cloudflare/#42-lock-warp-client
#
# The lock settings are written by the single default-profile resource in
# pack 4.1. This pack verifies them (Terraform >= 1.5 `check` block) without
# declaring a second resource on the same singleton object.
# =============================================================================

# HTH Guide Excerpt: begin terraform
check "warp_client_locked" {
  data "cloudflare_zero_trust_device_default_profile" "current" {
    account_id = var.cloudflare_account_id
  }

  assert {
    condition     = data.cloudflare_zero_trust_device_default_profile.current.switch_locked == true
    error_message = "Lock device client switch is off: users can turn the client off."
  }

  assert {
    condition     = data.cloudflare_zero_trust_device_default_profile.current.allowed_to_leave == false
    error_message = "Users are allowed to leave the Zero Trust organization from the client."
  }

  # The guide's Timeout of 1-15 minutes, in seconds; 0 lets a switched-off
  # client stay off indefinitely. The same range as api pack 4.01.
  assert {
    condition = (
      data.cloudflare_zero_trust_device_default_profile.current.auto_connect >= 60 &&
      data.cloudflare_zero_trust_device_default_profile.current.auto_connect <= 900
    )
    error_message = "Auto connect is outside 60-900 seconds (the guide's 1-15 minute Timeout); 0 lets a switched-off client stay off indefinitely."
  }
}
# HTH Guide Excerpt: end terraform
