# =============================================================================
# Google Workspace Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Multi-Factor Authentication
# -----------------------------------------------------------------------------

output "mfa_enforcement_ou_id" {
  description = "ID of the MFA Enforcement organizational unit"
  value       = googleworkspace_org_unit.mfa_enforcement.id
}

output "mfa_not_enrolled_group_id" {
  description = "ID of the MFA Not Enrolled tracking group"
  value       = googleworkspace_group.mfa_not_enrolled.id
}

output "super_admin_mfa_ou_id" {
  description = "ID of the Super Admin security-key-only OU (L3 only)"
  value       = var.profile_level >= 3 ? googleworkspace_org_unit.super_admin_mfa[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Super Admin Governance
# -----------------------------------------------------------------------------

output "user_admin_role_id" {
  description = "ID of the delegated User Administrator role"
  value       = googleworkspace_role.user_admin.id
}

output "groups_admin_role_id" {
  description = "ID of the delegated Groups Administrator role"
  value       = googleworkspace_role.groups_admin.id
}

output "help_desk_admin_role_id" {
  description = "ID of the delegated Help Desk Administrator role"
  value       = googleworkspace_role.help_desk_admin.id
}

output "super_admins_ou_id" {
  description = "ID of the Super Admins organizational unit"
  value       = googleworkspace_org_unit.super_admins.id
}

output "super_admin_audit_group_id" {
  description = "ID of the Super Admin audit tracking group"
  value       = googleworkspace_group.super_admin_audit.id
}


# -----------------------------------------------------------------------------
# Section 1.3: Context-Aware Access (L2+)
# -----------------------------------------------------------------------------

output "access_policy_name" {
  description = "Name of the Access Context Manager policy (L2+ only)"
  value       = var.profile_level >= 2 && var.organization_id != "" ? google_access_context_manager_access_policy.workspace[0].name : null
}

output "managed_device_access_level" {
  description = "Name of the managed device access level (L2+ only)"
  value       = var.profile_level >= 2 && var.organization_id != "" ? google_access_context_manager_access_level.managed_device[0].name : null
}

output "corp_device_access_level" {
  description = "Name of the corporate-owned device access level (L3 only)"
  value       = var.profile_level >= 3 && var.organization_id != "" ? google_access_context_manager_access_level.corp_device[0].name : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Admin Console IP Restrictions (L2+)
# -----------------------------------------------------------------------------

output "admin_ip_allowlist_access_level" {
  description = "Name of the Admin Console IP allowlist access level (L2+ only)"
  value       = var.profile_level >= 2 && length(var.admin_allowed_cidrs) > 0 && var.organization_id != "" ? google_access_context_manager_access_level.admin_ip_allowlist[0].name : null
}


# -----------------------------------------------------------------------------
# Section 3.1: OAuth App Whitelisting
# -----------------------------------------------------------------------------

output "oauth_reviewers_group_id" {
  description = "ID of the OAuth app reviewers group"
  value       = googleworkspace_group.oauth_reviewers.id
}

output "oauth_blocked_alerts_group_id" {
  description = "ID of the OAuth blocked app alerts group"
  value       = googleworkspace_group.oauth_blocked_alerts.id
}

output "oauth_restricted_ou_id" {
  description = "ID of the OAuth restricted users OU (L2+ only)"
  value       = var.profile_level >= 2 ? googleworkspace_org_unit.oauth_restricted[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.2: Less Secure Apps
# -----------------------------------------------------------------------------

output "legacy_app_tracking_group_id" {
  description = "ID of the legacy app tracking group (should have zero members)"
  value       = googleworkspace_group.legacy_app_tracking.id
}


# -----------------------------------------------------------------------------
# Section 4.1: External Drive Sharing
# -----------------------------------------------------------------------------

output "external_sharing_allowed_ou_id" {
  description = "ID of the OU for teams with external sharing permissions"
  value       = googleworkspace_org_unit.external_sharing_allowed.id
}

output "no_external_sharing_ou_id" {
  description = "ID of the OU with no external sharing (L2+ only)"
  value       = var.profile_level >= 2 ? googleworkspace_org_unit.no_external_sharing[0].id : null
}

output "external_sharing_approvers_group_id" {
  description = "ID of the external sharing approvers group"
  value       = googleworkspace_group.external_sharing_approvers.id
}


# -----------------------------------------------------------------------------
# Section 4.2: Data Loss Prevention (L2+)
# -----------------------------------------------------------------------------

output "dlp_pii_template_id" {
  description = "ID of the DLP PII inspect template (L2+ only)"
  value       = var.profile_level >= 2 && var.gcp_project_id != "" ? google_data_loss_prevention_inspect_template.workspace_pii[0].id : null
}

output "dlp_regulated_template_id" {
  description = "ID of the DLP regulated data inspect template (L3 only)"
  value       = var.profile_level >= 3 && var.gcp_project_id != "" ? google_data_loss_prevention_inspect_template.workspace_regulated[0].id : null
}

output "dlp_incidents_group_id" {
  description = "ID of the DLP incidents notification group (L2+ only)"
  value       = var.profile_level >= 2 ? googleworkspace_group.dlp_incidents[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset for audit log export"
  value       = var.gcp_project_id != "" ? google_bigquery_dataset.audit_logs[0].dataset_id : null
}

output "security_alerts_group_id" {
  description = "ID of the security alerts notification group"
  value       = googleworkspace_group.security_alerts.id
}

output "admin_audit_group_id" {
  description = "ID of the admin audit notification group"
  value       = googleworkspace_group.admin_audit.id
}


# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "profile_level_applied" {
  description = "The hardening profile level that was applied"
  value       = var.profile_level
}

output "hardening_summary" {
  description = "Summary of hardening controls applied at the selected profile level"
  value = {
    profile_level               = var.profile_level
    l1_controls_applied         = true
    l2_controls_applied         = var.profile_level >= 2
    l3_controls_applied         = var.profile_level >= 3
    mfa_enforcement_ou          = "created"
    delegated_admin_roles       = "user_admin, groups_admin, help_desk_admin"
    context_aware_access        = var.profile_level >= 2 ? "configured" : "not_applicable"
    admin_ip_restriction        = var.profile_level >= 2 && length(var.admin_allowed_cidrs) > 0 ? "configured" : "not_configured"
    oauth_governance            = "groups_created"
    less_secure_apps            = "tracking_group_created"
    external_sharing            = "ou_structure_created"
    dlp                         = var.profile_level >= 2 ? "inspect_template_created" : "not_applicable"
    audit_logging               = var.gcp_project_id != "" ? "bigquery_export_configured" : "manual_configuration_required"
    bigquery_detection_views    = var.profile_level >= 2 ? "failed_logins, external_sharing" : "not_applicable"
  }
}
