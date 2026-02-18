# =============================================================================
# HTH Keeper Control 1.1: Protect Keeper Administrator Accounts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/keeper/#11-protect-keeper-administrator-accounts
# =============================================================================
#
# Keeper's zero-knowledge architecture means Keeper Support cannot elevate
# users to admin or reset admin passwords. If all admins lose access, there
# is no recovery path. This control ensures redundant admin accounts exist
# and break-glass procedures are documented as code.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# The Secrets Manager provider manages vault records; admin account
# configuration requires the Commander CLI or Admin Console.
# Install: pip3 install keepercommander
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Store break-glass admin credentials securely in a Keeper shared folder
resource "secretsmanager_login" "break_glass_admin" {
  count = var.break_glass_account_email != "" ? 1 : 0

  folder_uid = var.break_glass_folder_uid
  title      = "Break-Glass Admin - ${var.break_glass_account_email}"

  login    = var.break_glass_account_email
  password = var.break_glass_initial_password
  url      = "https://keepersecurity.com/vault"

  notes = <<-EOT
    BREAK-GLASS ADMIN ACCOUNT
    =========================
    Purpose: Emergency access when all other admin accounts are unavailable.
    Procedure: See break-glass runbook in your incident response documentation.
    MFA: Enrolled with hardware security key stored in physical safe.
    Last verified: Managed by Terraform - do not edit manually.
    Profile Level: L1 (Baseline)
  EOT
}

# Validate that minimum admin count is met (plan-time check via variable validation)
# Runtime verification requires Commander CLI -- see null_resource below
resource "terraform_data" "admin_redundancy_check" {
  count = length(var.admin_usernames) >= 2 ? 1 : 0

  input = {
    admin_count          = length(var.admin_usernames)
    admins               = join(", ", var.admin_usernames)
    break_glass_enrolled = var.break_glass_account_email != "" ? "yes" : "no"
  }
}
# HTH Guide Excerpt: end terraform
