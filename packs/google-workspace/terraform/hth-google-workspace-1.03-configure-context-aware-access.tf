# =============================================================================
# HTH Google Workspace Control 1.3: Configure Context-Aware Access
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.4/13.5, NIST AC-2(11)/AC-6(1)
# Source: https://howtoharden.com/guides/google-workspace/#13-configure-context-aware-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Context-Aware Access requires Google Workspace Enterprise Standard/Plus
# and uses Access Context Manager (part of BeyondCorp Enterprise).

# Access policy -- one per organization.  If you already have an access
# policy, import it rather than creating a new one.
resource "google_access_context_manager_access_policy" "workspace" {
  count = var.profile_level >= 2 && var.organization_id != "" ? 1 : 0

  parent = "organizations/${var.organization_id}"
  title  = var.access_policy_name
}

# Access level: require managed device with Endpoint Verification,
# disk encryption, and screen lock.
resource "google_access_context_manager_access_level" "managed_device" {
  count = var.profile_level >= 2 && var.organization_id != "" ? 1 : 0

  parent = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}/accessLevels/hth_managed_device"
  title  = "HTH Managed Device"

  basic {
    conditions {
      device_policy {
        require_screen_lock              = true
        allowed_encryption_statuses      = ["ENCRYPTED"]
        require_admin_approval           = false
        require_corp_owned               = false
        allowed_device_management_levels = ["BASIC", "COMPLETE"]
      }
    }
  }
}

# L3: Stricter access level requiring corporate-owned, fully managed devices
resource "google_access_context_manager_access_level" "corp_device" {
  count = var.profile_level >= 3 && var.organization_id != "" ? 1 : 0

  parent = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.workspace[0].name}/accessLevels/hth_corp_device"
  title  = "HTH Corporate-Owned Device"

  basic {
    conditions {
      device_policy {
        require_screen_lock              = true
        allowed_encryption_statuses      = ["ENCRYPTED"]
        require_admin_approval           = true
        require_corp_owned               = true
        allowed_device_management_levels = ["COMPLETE"]
      }
    }
  }
}
# HTH Guide Excerpt: end terraform
