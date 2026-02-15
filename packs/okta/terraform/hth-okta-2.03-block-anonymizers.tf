# =============================================================================
# HTH Okta Control 2.3: Dynamic Network Zones and Anonymizer Blocking
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3, SC-7
# Source: https://howtoharden.com/guides/okta/#23-configure-dynamic-network-zones
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Block anonymizing proxies and Tor exit nodes
resource "okta_network_zone" "block_anonymizers" {
  count = var.profile_level >= 2 ? 1 : 0

  name               = "Block Anonymizers"
  type               = "DYNAMIC_V2"
  status             = "ACTIVE"
  usage              = "BLOCKLIST"
  dynamic_proxy_type = "TorAnonymizer"
}

# Block traffic from high-risk countries
resource "okta_network_zone" "block_countries" {
  count = var.profile_level >= 2 ? 1 : 0

  name              = "Blocked Countries"
  type              = "DYNAMIC"
  status            = "ACTIVE"
  usage             = "BLOCKLIST"
  dynamic_locations = var.blocked_countries
}
# HTH Guide Excerpt: end terraform
