# =============================================================================
# HTH Microsoft Entra ID Control 2.3: Require Compliant Devices for Admins
# Profile Level: L2 (Hardened)
# Frameworks: CIS 4.1/6.4, NIST AC-2(11)/AC-6(1)
# Source: https://howtoharden.com/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Conditional Access policy requiring compliant or Hybrid Azure AD joined
# devices for all privileged admin access to Microsoft admin portals
resource "azuread_conditional_access_policy" "require_compliant_device_admins" {
  count = var.profile_level >= 2 ? 1 : 0

  display_name = "HTH: Require compliant device for admins"
  state        = "enabled"

  conditions {
    users {
      included_roles  = length(var.admin_role_ids) > 0 ? var.admin_role_ids : [
        # Default: target common privileged roles
        data.azuread_directory_role.global_admin.template_id,
      ]
      excluded_groups = [azuread_group.emergency_access.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["browser", "mobileAppsAndDesktopClients"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["compliantDevice", "domainJoinedDevice"]
  }
}
# HTH Guide Excerpt: end terraform
