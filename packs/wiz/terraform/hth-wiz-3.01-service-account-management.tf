# =============================================================================
# HTH Wiz Control 3.1: Service Account Management
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/wiz/#31-service-account-management
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create purpose-specific service accounts with minimum scopes
# Each integration gets its own account with only required permissions:
#   SIEM:       read:issues, read:vulnerabilities
#   Ticketing:  read:issues
#   Automation: Specific to use case
resource "wiz_service_account" "integration" {
  for_each = { for sa in var.service_accounts : sa.name => sa }

  name   = each.value.name
  type   = "THIRD_PARTY"
  scopes = each.value.scopes

  # Detect external credential rotation and force resource recreation
  recreate_if_rotated = true
}
# HTH Guide Excerpt: end terraform
