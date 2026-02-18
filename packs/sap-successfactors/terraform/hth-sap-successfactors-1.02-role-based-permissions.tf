# =============================================================================
# HTH SAP SuccessFactors Control 1.2: Role-Based Permissions (RBP)
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/sap-successfactors/#12-role-based-permissions-rbp
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create a role collection for SuccessFactors System Administrators (minimal users)
resource "btp_subaccount_role_collection" "sf_system_admin" {
  subaccount_id = var.btp_subaccount_id
  name          = "HTH SF System Admin"
  description   = "HTH: Restricted system admin role -- limit to essential personnel only"

  roles {
    name                 = "Subaccount Administrator"
    role_template_app_id = "cis-local!b2"
    role_template_name   = "Subaccount_Admin"
  }
}

# Assign system admin role to explicitly listed users only
resource "btp_subaccount_role_collection_assignment" "sf_admin_users" {
  for_each = toset(var.admin_users)

  subaccount_id        = var.btp_subaccount_id
  role_collection_name = btp_subaccount_role_collection.sf_system_admin.name
  user_name            = each.value
  origin               = "corporate-idp"
}

# Create a role collection for HR Administrators
resource "btp_subaccount_role_collection" "sf_hr_admin" {
  subaccount_id = var.btp_subaccount_id
  name          = "HTH SF HR Admin"
  description   = "HTH: HR admin role -- employee data management only, no system config"

  roles {
    name                 = "Subaccount Viewer"
    role_template_app_id = "cis-local!b2"
    role_template_name   = "Subaccount_Viewer"
  }
}

# Assign HR admin role to explicitly listed users
resource "btp_subaccount_role_collection_assignment" "sf_hr_admin_users" {
  for_each = toset(var.hr_admin_users)

  subaccount_id        = var.btp_subaccount_id
  role_collection_name = btp_subaccount_role_collection.sf_hr_admin.name
  user_name            = each.value
  origin               = "corporate-idp"
}

# L2+: Create a read-only auditor role for separation of duties
resource "btp_subaccount_role_collection" "sf_auditor" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id = var.btp_subaccount_id
  name          = "HTH SF Auditor"
  description   = "HTH: Read-only auditor role for compliance review -- no write access"

  roles {
    name                 = "Subaccount Viewer"
    role_template_app_id = "cis-local!b2"
    role_template_name   = "Subaccount_Viewer"
  }
}
# HTH Guide Excerpt: end terraform
