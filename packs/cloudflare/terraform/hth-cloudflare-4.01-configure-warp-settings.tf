# =============================================================================
# HTH Cloudflare Control 4.1: Configure WARP Client Settings
# Profile Level: L1 (Crawl)
# Frameworks: NIST CM-7, SC-7 | CIS 4.1
# Source: https://howtoharden.com/guides/cloudflare/#41-configure-warp-client-settings
#
# The default device profile is ONE object per account. This is the only pack
# that writes it: the lock settings from 4.2 and the split tunnel exclusions
# from 4.3 are declared here, and packs 4.2 and 4.3 only verify them with
# `check` blocks. Two resources on the same singleton would overwrite each
# other on every apply.
#   auto_connect   var.warp_auto_connect_seconds (default 900, allowed 60-900) --
#                  the guide's 1-15 minute Timeout; 0 = stays off forever
#   captive_portal var.warp_captive_portal_seconds (default 180, must be > 0)
# If the account already runs a stricter value (a shorter auto_connect or
# captive_portal), set the variable to it: apply writes the value given, and
# the default would lengthen the window the client is off.
# tunnel_protocol is left unset so the account keeps the default, MASQUE
# (FIPS 140-3 compliant cipher suite).
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_device_default_profile" "default" {
  account_id        = var.cloudflare_account_id
  auto_connect      = var.warp_auto_connect_seconds
  captive_portal    = var.warp_captive_portal_seconds
  allow_mode_switch = false
  allow_updates     = true
  switch_locked     = true
  allowed_to_leave  = false

  service_mode_v2 = {
    mode = "warp"
  }

  # Split Tunnels in Exclude mode: only these destinations bypass Gateway
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
