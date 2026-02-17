# =============================================================================
# HTH Snowflake Control 2.1: Implement Network Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7
# Source: https://howtoharden.com/guides/snowflake/#21-implement-network-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Network policy restricting access to corporate IP ranges
resource "snowflake_network_policy" "corporate_access" {
  name    = "HTH_CORPORATE_ACCESS"
  comment = "HTH: Restrict account access to corporate IP ranges (Control 2.1)"

  allowed_ip_list = var.allowed_ip_list
  blocked_ip_list = var.blocked_ip_list
}

# Attach network policy at account level
resource "snowflake_network_policy_attachment" "account_level" {
  network_policy_name = snowflake_network_policy.corporate_access.name
  set_for_account     = true
}

# Optional: stricter network policy for service accounts
resource "snowflake_network_policy" "service_accounts" {
  count = length(var.service_account_allowed_ips) > 0 ? 1 : 0

  name    = "HTH_SERVICE_ACCOUNT_ACCESS"
  comment = "HTH: Restrict service account access to known IPs (Control 2.1)"

  allowed_ip_list = var.service_account_allowed_ips
  blocked_ip_list = []
}
# HTH Guide Excerpt: end terraform
