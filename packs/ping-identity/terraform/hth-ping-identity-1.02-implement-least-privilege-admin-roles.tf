# =============================================================================
# HTH Ping Identity Control 1.2: Least-Privilege Admin Roles
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6, AC-6(1)
# Source: https://howtoharden.com/guides/ping-identity/#12-implement-least-privilege-admin-roles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Groups for role-based admin access
resource "pingone_group" "identity_admins" {
  environment_id = var.pingone_environment_id
  name           = "HTH Identity Administrators"
  description    = "Manage users, groups, reset passwords, assign MFA. No application or policy config."
}

resource "pingone_group" "app_admins" {
  environment_id = var.pingone_environment_id
  name           = "HTH Application Administrators"
  description    = "Configure SAML/OIDC applications and application policies. No user management."
}

resource "pingone_group" "security_admins" {
  environment_id = var.pingone_environment_id
  name           = "HTH Security Administrators"
  description    = "Configure MFA and authentication policies, access audit logs. No direct app management."
}

resource "pingone_group" "auditors" {
  environment_id = var.pingone_environment_id
  name           = "HTH Read-Only Auditors"
  description    = "View all configurations, access reports and logs. No write access."
}

# Role assignments -- Identity Admin
resource "pingone_group_role_assignment" "identity_admin_role" {
  count = var.identity_admin_group_id != "" ? 1 : 0

  environment_id = var.pingone_environment_id
  group_id       = pingone_group.identity_admins.id
  role_id        = data.pingone_role.identity_data_admin.id

  scope_environment_id = var.pingone_environment_id
}

# Role assignments -- Application Admin
resource "pingone_group_role_assignment" "app_admin_role" {
  count = var.app_admin_group_id != "" ? 1 : 0

  environment_id = var.pingone_environment_id
  group_id       = pingone_group.app_admins.id
  role_id        = data.pingone_role.application_owner.id

  scope_environment_id = var.pingone_environment_id
}

# Role assignments -- Security Admin
resource "pingone_group_role_assignment" "security_admin_role" {
  count = var.security_admin_group_id != "" ? 1 : 0

  environment_id = var.pingone_environment_id
  group_id       = pingone_group.security_admins.id
  role_id        = data.pingone_role.environment_admin.id

  scope_environment_id = var.pingone_environment_id
}

# Data sources for built-in PingOne roles
data "pingone_role" "identity_data_admin" {
  name = "Identity Data Admin"
}

data "pingone_role" "application_owner" {
  name = "Application Owner"
}

data "pingone_role" "environment_admin" {
  name = "Environment Admin"
}

data "pingone_role" "identity_data_read_only" {
  name = "Identity Data Read Only"
}

# L2+: Enforce group-only role assignments (no direct user roles)
# This is enforced via policy; direct user role assignments should be audited
resource "pingone_group_role_assignment" "auditor_role" {
  environment_id = var.pingone_environment_id
  group_id       = pingone_group.auditors.id
  role_id        = data.pingone_role.identity_data_read_only.id

  scope_environment_id = var.pingone_environment_id
}
# HTH Guide Excerpt: end terraform
