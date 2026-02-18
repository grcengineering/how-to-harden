# =============================================================================
# HTH Zscaler Control 2.3: Configure Firewall Policies
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-7, AC-4 | CIS 4.4, 13.4
# Source: https://howtoharden.com/guides/zscaler/#23-configure-firewall-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Block risky protocols -- unencrypted and tunneling traffic (L2+)
resource "zia_firewall_filtering_rule" "block_risky_protocols" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH-Block-Risky-Protocols"
  description = "Block unencrypted protocols, tunneling, and unauthorized remote access"
  state       = "ENABLED"
  action      = "BLOCK_DROP"
  order       = 1

  nw_services {
    id = [data.zia_firewall_filtering_network_services.ftp.id]
  }

  protocols = ["FTP_RULE", "NETBIOS_RULE"]
}

# Default deny rule -- all traffic not explicitly allowed is blocked (L2+)
resource "zia_firewall_filtering_rule" "default_deny" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH-Default-Deny"
  description = "Default deny rule -- block all traffic not explicitly permitted"
  state       = "ENABLED"
  action      = "BLOCK_DROP"
  order       = 10000
}

# Data source: FTP network service for block rule
data "zia_firewall_filtering_network_services" "ftp" {
  name = "FTP"
}

# HTH Guide Excerpt: end terraform
