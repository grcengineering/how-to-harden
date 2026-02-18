# =============================================================================
# HTH Databricks Control 1.3: IP Access Lists
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3(7), SOC 2 CC6.6
# Source: https://howtoharden.com/guides/databricks/#13-configure-ip-access-lists
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Allowlist: Restrict workspace access to known corporate IP ranges (L2+)
resource "databricks_ip_access_list" "allow_corporate" {
  count = var.profile_level >= 2 && length(var.allowed_ip_cidrs) > 0 ? 1 : 0

  label        = "HTH - Corporate Network Allow List"
  list_type    = "ALLOW"
  ip_addresses = var.allowed_ip_cidrs

  depends_on = [databricks_workspace_conf.sso_enforcement]
}

# Blocklist: Deny access from known-bad IP ranges (L2+)
resource "databricks_ip_access_list" "block_bad_ips" {
  count = var.profile_level >= 2 && length(var.blocked_ip_cidrs) > 0 ? 1 : 0

  label        = "HTH - Blocked IP Ranges"
  list_type    = "BLOCK"
  ip_addresses = var.blocked_ip_cidrs

  depends_on = [databricks_workspace_conf.sso_enforcement]
}
# HTH Guide Excerpt: end terraform
