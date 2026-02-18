# =============================================================================
# HTH Harness Control 2.3: Limit Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/harness/#23-limit-admin-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Restricted administrator user group -- limit to 2-3 members
resource "harness_platform_usergroup" "platform_admins" {
  identifier = "hth_platform_admins"
  name       = var.admin_user_group_name
  description = "Restricted platform administrator group -- limit to 2-3 members (HTH Control 2.3)"

  notification_configs {
    type              = "EMAIL"
    send_email_to_all = true
  }
}

# Resource group for account-level admin operations
resource "harness_platform_resource_group" "account_admin" {
  identifier  = "hth_account_admin"
  name        = "Account Administration"
  description = "Resource group for account-level administrative operations (HTH Control 2.3)"
  account_id  = var.harness_account_id

  included_scopes {
    filter = "INCLUDING_CHILD_SCOPES"
  }

  resource_filter {
    include_all_resources = true
  }
}

# Bind the Account Admin role to the restricted admin group
resource "harness_platform_role_assignments" "admin_binding" {
  identifier = "hth_admin_binding"

  resource_group_identifier = harness_platform_resource_group.account_admin.id
  role_identifier           = "_account_admin"
  principal {
    identifier = harness_platform_usergroup.platform_admins.id
    type       = "USER_GROUP"
  }
  disabled   = false
  managed    = false
}
# HTH Guide Excerpt: end terraform
