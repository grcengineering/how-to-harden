# =============================================================================
# HTH Microsoft 365 Control 1.4: Configure Break-Glass Emergency Access Accounts
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/microsoft-365/#14-configure-break-glass-emergency-access-accounts
# =============================================================================

# HTH Guide Excerpt: begin terraform

locals {
  # Only create break-glass accounts if domain and passwords are provided
  create_break_glass = (
    var.break_glass_account_domain != "" &&
    length(var.break_glass_account_passwords) >= 2
  )
}

# Break-glass emergency access account 1
# Cloud-only, excluded from all Conditional Access policies
resource "azuread_user" "break_glass_01" {
  count = local.create_break_glass ? 1 : 0

  user_principal_name = "emergency-admin-01@${var.break_glass_account_domain}"
  display_name        = "Emergency Admin 01"
  password            = var.break_glass_account_passwords[0]
  account_enabled     = true

  # Prevent password expiry on emergency accounts
  disable_password_expiration = true
  disable_strong_password     = false
}

# Break-glass emergency access account 2
resource "azuread_user" "break_glass_02" {
  count = local.create_break_glass ? 1 : 0

  user_principal_name = "emergency-admin-02@${var.break_glass_account_domain}"
  display_name        = "Emergency Admin 02"
  password            = var.break_glass_account_passwords[1]
  account_enabled     = true

  disable_password_expiration = true
  disable_strong_password     = false
}

# Activate Global Administrator role for break-glass assignment
resource "azuread_directory_role" "global_admin_break_glass" {
  count = local.create_break_glass ? 1 : 0

  template_id = "62e90394-69f5-4237-9190-012177145e10"
}

# Assign Global Administrator to break-glass account 1
resource "azuread_directory_role_assignment" "break_glass_01_admin" {
  count = local.create_break_glass ? 1 : 0

  role_id             = azuread_directory_role.global_admin_break_glass[0].template_id
  principal_object_id = azuread_user.break_glass_01[0].object_id
}

# Assign Global Administrator to break-glass account 2
resource "azuread_directory_role_assignment" "break_glass_02_admin" {
  count = local.create_break_glass ? 1 : 0

  role_id             = azuread_directory_role.global_admin_break_glass[0].template_id
  principal_object_id = azuread_user.break_glass_02[0].object_id
}

# HTH Guide Excerpt: end terraform
