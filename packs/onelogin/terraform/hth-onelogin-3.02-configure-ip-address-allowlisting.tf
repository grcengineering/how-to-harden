# =============================================================================
# HTH OneLogin Control 3.2: Configure IP Address Allowlisting
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17, SC-7
# Source: https://howtoharden.com/guides/onelogin/#32-configure-ip-address-allowlisting
# =============================================================================

# HTH Guide Excerpt: begin terraform
# IP address restriction policy -- only allow login from approved networks
# Only deployed at L2+ for environments requiring network-level access control
resource "onelogin_user_security_policy" "ip_allowlist" {
  count = var.profile_level >= 2 && var.allowed_ip_addresses != "" ? 1 : 0

  name = "HTH IP Allowlist Policy"

  # Restrict login to approved IP addresses
  ip_address_restriction  = true
  allowed_ip_addresses    = var.allowed_ip_addresses
  ip_restriction_action   = "deny"
}

# L3: Block and alert on unauthorized IP access
resource "onelogin_user_security_policy" "ip_allowlist_max" {
  count = var.profile_level >= 3 && var.allowed_ip_addresses != "" ? 1 : 0

  name = "HTH IP Allowlist Policy - Maximum Security"

  ip_address_restriction = true
  allowed_ip_addresses   = var.allowed_ip_addresses
  ip_restriction_action  = "deny"
}
# HTH Guide Excerpt: end terraform
