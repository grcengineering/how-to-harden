# =============================================================================
# HTH Harness Control 1.3: Configure IP Allowlisting
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17
# Source: https://howtoharden.com/guides/harness/#13-configure-ip-allowlisting
# =============================================================================

# HTH Guide Excerpt: begin terraform
# IP allowlist restricts platform access to approved network ranges.
# Only applied at L2+ profile levels.
resource "harness_platform_ip_allowlist" "corporate" {
  count = var.profile_level >= 2 && length(var.allowed_source_cidrs) > 0 ? 1 : 0

  identifier       = "hth_corporate_allowlist"
  name             = var.ip_allowlist_name
  description      = "Restrict access to approved corporate IP ranges (HTH Control 1.3)"
  allowed_source_type = "IP_ADDRESS"
  ip_address       = var.allowed_source_cidrs[0]
  enabled          = true
}

# Additional allowlist entries for each CIDR beyond the first
resource "harness_platform_ip_allowlist" "corporate_additional" {
  count = var.profile_level >= 2 ? max(length(var.allowed_source_cidrs) - 1, 0) : 0

  identifier       = "hth_corporate_allowlist_${count.index + 1}"
  name             = "${var.ip_allowlist_name} ${count.index + 2}"
  description      = "Additional corporate IP range ${count.index + 2} (HTH Control 1.3)"
  allowed_source_type = "IP_ADDRESS"
  ip_address       = var.allowed_source_cidrs[count.index + 1]
  enabled          = true
}
# HTH Guide Excerpt: end terraform
