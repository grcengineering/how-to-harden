# =============================================================================
# HTH Microsoft Entra ID Control 3.1: Enable Just-In-Time Access for Admin Roles
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4/6.8, NIST AC-2(7)/AC-6(1), CIS Azure 1.1.4
# Source: https://howtoharden.com/guides/microsoft-entra-id/#31-enable-just-in-time-access-for-admin-roles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create PIM eligible assignments for Global Administrator role.
# Eliminates standing admin privileges by requiring just-in-time activation
# with MFA, justification, and optional approval.
#
# NOTE: Full PIM role settings (activation duration, approval workflow,
# MFA on activation) require Microsoft Graph API or the admin center.
# Terraform manages eligible assignments; configure role settings via
# the Entra admin center or PowerShell.
resource "azuread_directory_role_eligibility_schedule_request" "pim_global_admin" {
  count = var.profile_level >= 2 ? length(var.pim_eligible_user_ids) : 0

  role_definition_id = data.azuread_directory_role.global_admin.template_id
  principal_id       = var.pim_eligible_user_ids[count.index]
  directory_scope_id = "/"
  justification      = "HTH: PIM eligible assignment for Just-In-Time access"

  schedule_info {
    expiration {
      duration = "P${var.pim_eligibility_duration_days}D"
      type     = "afterDuration"
    }
  }
}
# HTH Guide Excerpt: end terraform
