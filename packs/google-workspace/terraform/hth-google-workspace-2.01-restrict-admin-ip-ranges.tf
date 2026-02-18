# =============================================================================
# HTH Google Workspace Control 2.1: Configure Allowed IP Ranges for Admin Console
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5, NIST AC-17/SC-7
# Source: https://howtoharden.com/guides/google-workspace/#21-configure-allowed-ip-ranges-for-admin-console
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Restrict Admin Console access to known corporate IP ranges.
# Uses Access Context Manager to create an IP-based access level that
# can be applied to Admin Console and other sensitive applications.

resource "google_access_context_manager_access_level" "admin_ip_allowlist" {
  count = var.profile_level >= 2 && length(var.admin_allowed_cidrs) > 0 && var.organization_id != "" ? 1 : 0

  parent = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}/accessLevels/hth_admin_ip_allowlist"
  title  = "HTH Admin Console IP Allowlist"

  basic {
    conditions {
      ip_subnetworks = var.admin_allowed_cidrs
    }
  }
}

# L3: Combine IP restriction with managed device requirement
resource "google_access_context_manager_access_level" "admin_ip_and_device" {
  count = var.profile_level >= 3 && length(var.admin_allowed_cidrs) > 0 && var.organization_id != "" ? 1 : 0

  parent = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}/accessLevels/hth_admin_ip_and_device"
  title  = "HTH Admin Console IP + Device"

  basic {
    combining_function = "AND"

    conditions {
      ip_subnetworks = var.admin_allowed_cidrs
    }

    conditions {
      device_policy {
        require_screen_lock              = true
        allowed_encryption_statuses      = ["ENCRYPTED"]
        require_corp_owned               = true
        allowed_device_management_levels = ["COMPLETE"]
      }
    }
  }
}
# HTH Guide Excerpt: end terraform
