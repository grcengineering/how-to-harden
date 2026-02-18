# =============================================================================
# HTH Microsoft Entra ID Control 1.2: Configure Emergency Access (Break-Glass) Accounts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.1, NIST AC-2, CIS Azure 1.1.5
# Source: https://howtoharden.com/guides/microsoft-entra-id/#12-configure-emergency-access-break-glass-accounts
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create emergency access (break-glass) accounts
resource "azuread_user" "emergency_admin" {
  count = var.emergency_account_count

  user_principal_name = "${var.emergency_account_upn_prefix}-${format("%02d", count.index + 1)}@${var.domain_name}"
  display_name        = "Emergency Admin ${format("%02d", count.index + 1)}"
  mail_nickname       = "${var.emergency_account_upn_prefix}-${format("%02d", count.index + 1)}"
  account_enabled     = true

  # Password is managed outside Terraform -- generate a 64+ character
  # random password and store it in a physically secure location (safe/vault).
  # Terraform manages the account lifecycle, not the credential.
  password                    = random_password.emergency[count.index].result
  force_password_change       = false
  disable_password_expiration = true
  disable_strong_password     = false

  lifecycle {
    ignore_changes = [password]
  }
}

# Generate initial passwords for emergency accounts
resource "random_password" "emergency" {
  count = var.emergency_account_count

  length           = 64
  special          = true
  override_special = "!@#$%&*()-_=+[]{}|;:,.<>?"
}

# Look up the Global Administrator role
data "azuread_directory_role" "global_admin" {
  display_name = "Global Administrator"
}

# Assign Global Administrator role to emergency accounts
resource "azuread_directory_role_assignment" "emergency_global_admin" {
  count = var.emergency_account_count

  role_id             = data.azuread_directory_role.global_admin.template_id
  principal_object_id = azuread_user.emergency_admin[count.index].object_id
}

# Create a group for emergency accounts (used for Conditional Access exclusions)
resource "azuread_group" "emergency_access" {
  display_name     = "HTH Emergency Access Accounts"
  description      = "Break-glass accounts excluded from Conditional Access policies"
  security_enabled = true
  mail_enabled     = false

  members = azuread_user.emergency_admin[*].object_id
}
# HTH Guide Excerpt: end terraform
