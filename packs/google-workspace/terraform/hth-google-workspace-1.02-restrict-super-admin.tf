# =============================================================================
# HTH Google Workspace Control 1.2: Restrict Super Admin Account Usage
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)/AC-6(5), CIS Google Workspace 1.2
# Source: https://howtoharden.com/guides/google-workspace/#12-restrict-super-admin-account-usage
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create delegated admin roles following the principle of least privilege.
# Super Admin accounts should be limited to 2-4; day-to-day admin tasks
# should use these scoped roles instead.

resource "googleworkspace_role" "user_admin" {
  name        = "HTH User Administrator"
  description = "HTH 1.2 -- Delegated role for user management (password resets, profile updates)"

  privileges {
    service_id = "00haapch16h1ysv"  # Admin SDK - Users
    privilege  = "USERS_RETRIEVE"
  }
  privileges {
    service_id = "00haapch16h1ysv"
    privilege  = "USERS_UPDATE"
  }
  privileges {
    service_id = "00haapch16h1ysv"
    privilege  = "USERS_ALIAS"
  }
}

resource "googleworkspace_role" "groups_admin" {
  name        = "HTH Groups Administrator"
  description = "HTH 1.2 -- Delegated role for group management (create, update, membership)"

  privileges {
    service_id = "00haapch16h1ysv"
    privilege  = "GROUPS_RETRIEVE"
  }
  privileges {
    service_id = "00haapch16h1ysv"
    privilege  = "GROUPS_UPDATE"
  }
}

resource "googleworkspace_role" "help_desk_admin" {
  name        = "HTH Help Desk Administrator"
  description = "HTH 1.2 -- Delegated role for help desk (password resets, view user info)"

  privileges {
    service_id = "00haapch16h1ysv"
    privilege  = "USERS_RETRIEVE"
  }
  privileges {
    service_id = "00haapch16h1ysv"
    privilege  = "USERS_UPDATE"
  }
}

# Create custom delegated roles from variable input
resource "googleworkspace_role" "custom" {
  for_each = var.delegated_admin_roles

  name        = each.key
  description = each.value.description

  dynamic "privileges" {
    for_each = each.value.privileges
    content {
      service_id = privileges.value.service_id
      privilege  = privileges.value.privilege
    }
  }
}

# Create an OU for Super Admin accounts so security-key-only 2SV
# can be applied at the OU level via Admin Console.
resource "googleworkspace_org_unit" "super_admins" {
  name                 = "Super Admins"
  description          = "HTH 1.2 -- Dedicated OU for Super Admin accounts with security-key-only 2SV"
  parent_org_unit_path = var.target_org_unit_path
}

# Group for auditing Super Admin role holders.
# Membership should be manually managed and kept to 2-4 accounts.
resource "googleworkspace_group" "super_admin_audit" {
  email       = "super-admin-audit@${var.primary_domain}"
  name        = "Super Admin Audit"
  description = "HTH 1.2 -- Tracks Super Admin role holders. Should contain 2-4 members maximum."
}
# HTH Guide Excerpt: end terraform
