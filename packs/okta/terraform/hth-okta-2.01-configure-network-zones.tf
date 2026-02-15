# =============================================================================
# HTH Okta Control 2.1: Network Zones
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.7, NIST AC-3, SC-7
# Source: https://howtoharden.com/guides/okta/#21-configure-ip-zones-and-network-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Corporate network zone with configurable CIDRs
resource "okta_network_zone" "corporate" {
  count = length(var.corporate_gateway_cidrs) > 0 ? 1 : 0

  name     = "Corporate Network"
  type     = "IP"
  status   = "ACTIVE"
  gateways = var.corporate_gateway_cidrs
}

# IP blocklist zone
resource "okta_network_zone" "blocklist" {
  count = length(var.blocked_ip_cidrs) > 0 ? 1 : 0

  name     = "Blocked IPs"
  type     = "IP"
  status   = "ACTIVE"
  usage    = "BLOCKLIST"
  gateways = var.blocked_ip_cidrs
}
# HTH Guide Excerpt: end terraform
