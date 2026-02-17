# =============================================================================
# HTH Cloudflare Control 3.3: Configure Network Policies
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-7, AC-4 | CIS 4.4, 13.4
# Source: https://howtoharden.com/guides/cloudflare/#33-configure-network-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "block_risky_protocols" {
  account_id = var.cloudflare_account_id
  name       = "Block SSH to external hosts"
  action     = "block"
  filters    = ["l4"]
  traffic    = "net.dst.port == 22 and net.dst.ip !in {10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}"
  enabled    = true
  precedence = 10
}

resource "cloudflare_zero_trust_gateway_policy" "audit_rdp" {
  account_id = var.cloudflare_account_id
  name       = "Audit RDP connections"
  action     = "allow"
  filters    = ["l4"]
  traffic    = "net.dst.port == 3389"
  enabled    = true
  precedence = 20
}
# HTH Guide Excerpt: end terraform
