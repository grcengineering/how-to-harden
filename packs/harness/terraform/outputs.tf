# =============================================================================
# Harness Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SAML Single Sign-On
# -----------------------------------------------------------------------------

output "sso_linked_admins_id" {
  description = "ID of the SSO-linked administrator user group"
  value       = harness_platform_usergroup.sso_linked_admins.id
}

output "sso_users_id" {
  description = "ID of the SSO-linked general users group"
  value       = harness_platform_usergroup.sso_users.id
}


# -----------------------------------------------------------------------------
# Section 1.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

output "mfa_enforced_admins_id" {
  description = "ID of the MFA-enforced administrator group"
  value       = harness_platform_usergroup.mfa_enforced_admins.id
}

output "automation_service_account_id" {
  description = "ID of the automation service account (SAT-authenticated)"
  value       = harness_platform_service_account.automation.id
}


# -----------------------------------------------------------------------------
# Section 1.3: IP Allowlisting (L2+)
# -----------------------------------------------------------------------------

output "ip_allowlist_id" {
  description = "ID of the primary IP allowlist configuration (L2+ only)"
  value       = var.profile_level >= 2 && length(var.allowed_source_cidrs) > 0 ? harness_platform_ip_allowlist.corporate[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

output "pipeline_executor_role_id" {
  description = "ID of the pipeline executor least-privilege role"
  value       = harness_platform_roles.pipeline_executor.id
}

output "viewer_role_id" {
  description = "ID of the read-only viewer role"
  value       = harness_platform_roles.viewer.id
}

output "project_pipelines_resource_group_id" {
  description = "ID of the project-scoped pipelines resource group"
  value       = harness_platform_resource_group.project_pipelines.id
}


# -----------------------------------------------------------------------------
# Section 2.2: Organization/Project Hierarchy (L2+)
# -----------------------------------------------------------------------------

output "organization_ids" {
  description = "Map of organization identifiers to their IDs (L2+ only)"
  value       = { for k, v in harness_platform_organization.org : k => v.id }
}

output "project_ids" {
  description = "Map of project identifiers to their IDs (L2+ only)"
  value       = { for k, v in harness_platform_project.project : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 2.3: Limit Admin Access
# -----------------------------------------------------------------------------

output "platform_admins_group_id" {
  description = "ID of the restricted platform administrators group"
  value       = harness_platform_usergroup.platform_admins.id
}

output "admin_role_binding_id" {
  description = "ID of the admin role assignment binding"
  value       = harness_platform_role_assignments.admin_binding.id
}


# -----------------------------------------------------------------------------
# Section 3.1: Secret Manager
# -----------------------------------------------------------------------------

output "vault_connector_id" {
  description = "ID of the HashiCorp Vault connector (if configured)"
  value       = var.secret_manager_type == "vault" ? harness_platform_connector_vault.vault[0].id : null
}

output "aws_secrets_connector_id" {
  description = "ID of the AWS Secrets Manager connector (if configured)"
  value       = var.secret_manager_type == "aws" ? harness_platform_connector_aws_secret_manager.aws[0].id : null
}

output "gcp_secrets_connector_id" {
  description = "ID of the GCP Secret Manager connector (if configured)"
  value       = var.secret_manager_type == "gcp" ? harness_platform_connector_gcp_secret_manager.gcp[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.2: Secret Access (L2+)
# -----------------------------------------------------------------------------

output "secret_resource_group_id" {
  description = "ID of the secret-scoped resource group (L2+ only)"
  value       = var.profile_level >= 2 ? harness_platform_resource_group.secrets[0].id : null
}

output "secret_operator_role_id" {
  description = "ID of the secret operator role (L2+ only)"
  value       = var.profile_level >= 2 ? harness_platform_roles.secret_operator[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Pipeline Governance (L2+)
# -----------------------------------------------------------------------------

output "pipeline_governance_policy_id" {
  description = "ID of the production approval governance policy (L2+ only)"
  value       = var.profile_level >= 2 ? harness_platform_policy.require_approval[0].id : null
}

output "pipeline_governance_policyset_id" {
  description = "ID of the pipeline governance policy set (L2+ only)"
  value       = var.profile_level >= 2 ? harness_platform_policyset.pipeline_governance[0].id : null
}

output "strict_governance_policyset_id" {
  description = "ID of the strict L3 pipeline governance policy set (L3 only)"
  value       = var.profile_level >= 3 ? harness_platform_policyset.strict_governance[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.2: Audit Trail
# -----------------------------------------------------------------------------

output "audit_viewer_role_id" {
  description = "ID of the audit trail viewer role"
  value       = harness_platform_roles.audit_viewer.id
}

output "auditors_group_id" {
  description = "ID of the audit and compliance team user group"
  value       = harness_platform_usergroup.auditors.id
}

output "audit_exporter_service_account_id" {
  description = "ID of the audit exporter service account (L2+ only)"
  value       = var.profile_level >= 2 ? harness_platform_service_account.audit_exporter[0].id : null
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
    profile_level          = var.profile_level
    l1_controls_applied    = true
    l2_controls_applied    = var.profile_level >= 2
    l3_controls_applied    = var.profile_level >= 3
    saml_sso               = "configured"
    mfa_enforcement        = "configured"
    ip_allowlisting        = var.profile_level >= 2 && length(var.allowed_source_cidrs) > 0
    rbac_roles             = "configured"
    org_hierarchy          = var.profile_level >= 2
    admin_access           = "restricted"
    secret_manager         = var.secret_manager_type
    secret_access_control  = var.profile_level >= 2
    pipeline_governance    = var.profile_level >= 2
    artifact_verification  = var.profile_level >= 3
    audit_trail            = "configured"
    audit_log_streaming    = var.profile_level >= 2
  }
}
