# =============================================================================
# Wiz Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

output "saml_idp_id" {
  description = "ID of the SAML identity provider"
  value       = var.saml_login_url != "" ? wiz_saml_idp.corporate_sso[0].id : null
}


# -----------------------------------------------------------------------------
# Section 1.2: Role-Based Access Control
# -----------------------------------------------------------------------------

output "rbac_group_mapping_id" {
  description = "ID of the SAML group-to-role mapping"
  value       = var.saml_idp_id != "" && length(var.rbac_group_mappings) > 0 ? wiz_saml_group_mapping.rbac[0].id : null
}

output "team_project_ids" {
  description = "Map of team project names to their Wiz IDs"
  value       = { for k, v in wiz_project.team_projects : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 2.1: Cloud Connector Security
# -----------------------------------------------------------------------------

output "aws_connector_id" {
  description = "ID of the hardened AWS cloud connector"
  value       = var.aws_connector_role_arn != "" ? wiz_connector_aws.hardened[0].id : null
}

output "aws_connector_external_id" {
  description = "External ID nonce for the AWS connector trust policy"
  value       = var.aws_connector_role_arn != "" ? wiz_connector_aws.hardened[0].external_id_nonce : null
  sensitive   = true
}

output "gcp_connector_id" {
  description = "ID of the hardened GCP cloud connector"
  value       = var.gcp_connector_organization_id != "" ? wiz_connector_gcp.hardened[0].id : null
}


# -----------------------------------------------------------------------------
# Section 2.2: Connector Credential Rotation (L2+)
# -----------------------------------------------------------------------------

output "credential_rotation_control_id" {
  description = "ID of the connector credential rotation monitoring control (L2+ only)"
  value       = var.profile_level >= 2 ? wiz_control.connector_credential_rotation[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Service Account Management
# -----------------------------------------------------------------------------

output "service_account_ids" {
  description = "Map of service account names to their Wiz IDs"
  value       = { for k, v in wiz_service_account.integration : k => v.id }
}

output "service_account_client_ids" {
  description = "Map of service account names to their client IDs"
  value       = { for k, v in wiz_service_account.integration : k => v.client_id }
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 3.2: API Access Monitoring (L2+)
# -----------------------------------------------------------------------------

output "api_audit_report_id" {
  description = "ID of the API access audit report (L2+ only)"
  value       = var.profile_level >= 2 ? wiz_report_graph_query.api_access_audit[0].id : null
}

output "overprivileged_sa_control_id" {
  description = "ID of the overprivileged service account detection control (L2+ only)"
  value       = var.profile_level >= 2 ? wiz_control.overprivileged_service_accounts[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Data Export Controls (L2+)
# -----------------------------------------------------------------------------

output "data_export_project_id" {
  description = "ID of the data-export-restricted project (L2+ only)"
  value       = var.profile_level >= 2 ? wiz_project.data_export_restricted[0].id : null
}

output "data_export_control_id" {
  description = "ID of the data export monitoring control (L2+ only)"
  value       = var.profile_level >= 2 ? wiz_control.data_export_monitoring[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

output "audit_log_report_id" {
  description = "ID of the scheduled audit log report"
  value       = wiz_report_graph_query.audit_log.id
}

output "siem_export_service_account_id" {
  description = "ID of the SIEM export service account"
  value       = wiz_service_account.siem_export.id
}

output "unusual_access_control_id" {
  description = "ID of the unusual data access pattern detection control"
  value       = wiz_control.unusual_data_access.id
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
    saml_sso_configured         = var.saml_login_url != ""
    rbac_group_mappings         = length(var.rbac_group_mappings)
    aws_connector               = var.aws_connector_role_arn != "" ? "configured" : "skipped"
    gcp_connector               = var.gcp_connector_organization_id != "" ? "configured" : "skipped"
    credential_rotation_monitor = var.profile_level >= 2
    service_accounts            = length(var.service_accounts)
    api_access_monitoring       = var.profile_level >= 2
    data_export_controls        = var.profile_level >= 2
    audit_logging               = "configured"
    siem_integration            = "configured"
  }
}
