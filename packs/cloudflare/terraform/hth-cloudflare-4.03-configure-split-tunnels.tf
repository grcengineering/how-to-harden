# =============================================================================
# HTH Cloudflare Control 4.3: Configure Split Tunnel Settings
# Profile Level: L2 (Walk)
# Frameworks: NIST SC-7 | CIS 13.5
# Source: https://howtoharden.com/guides/cloudflare/#43-configure-split-tunnel-settings
#
# The exclusion list is written by the single default-profile resource in
# pack 4.1. This pack verifies the default profile stays in Exclude mode
# (in Include mode every destination not listed bypasses Gateway filtering)
# and that every exclusion carries a description.
# =============================================================================

# HTH Guide Excerpt: begin terraform
check "split_tunnel_exclude_mode" {
  data "cloudflare_zero_trust_device_default_profile" "split" {
    account_id = var.cloudflare_account_id
  }

  assert {
    condition     = length(coalesce(data.cloudflare_zero_trust_device_default_profile.split.include, [])) == 0
    error_message = "Split Tunnels is in Include mode: traffic not listed bypasses Gateway."
  }

  assert {
    condition = alltrue([
      for route in coalesce(data.cloudflare_zero_trust_device_default_profile.split.exclude, []) :
      try(route.description, "") != ""
    ])
    error_message = "Every Split Tunnel exclusion needs a description recording its business justification."
  }
}
# HTH Guide Excerpt: end terraform
