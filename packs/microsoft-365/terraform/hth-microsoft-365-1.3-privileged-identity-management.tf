# =============================================================================
# HTH Microsoft 365 Control 1.3: Implement Privileged Identity Management (PIM)
# Profile Level: L2 (Hardened)
# Source: https://howtoharden.com/guides/microsoft-365/#13-implement-privileged-identity-management-pim
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Look up the Global Administrator directory role
data "azuread_directory_role_templates" "all" {}

locals {
  # Global Administrator role template ID
  global_admin_template_id = "62e90394-69f5-4237-9190-012177145e10"

  # Filter PIM-eligible admin UPNs -- only applied at L2+
  pim_admin_count = var.profile_level >= 2 ? length(var.pim_eligible_admin_upns) : 0
}

# Look up users to assign as PIM-eligible admins
data "azuread_user" "pim_admins" {
  count               = local.pim_admin_count
  user_principal_name = var.pim_eligible_admin_upns[count.index]
}

# Activate the Global Administrator directory role in the tenant
resource "azuread_directory_role" "global_admin" {
  count = var.profile_level >= 2 ? 1 : 0

  template_id = local.global_admin_template_id
}

# Create eligible (not permanent) role assignments for Global Administrator
# These require activation through PIM before use
resource "azuread_directory_role_eligibility_schedule_request" "pim_global_admin" {
  count = local.pim_admin_count

  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${local.global_admin_template_id}"
  principal_id       = data.azuread_user.pim_admins[count.index].object_id
  directory_scope_id = "/"
  justification      = "HTH: PIM eligible assignment for just-in-time Global Admin access"
}

# HTH Guide Excerpt: end terraform
