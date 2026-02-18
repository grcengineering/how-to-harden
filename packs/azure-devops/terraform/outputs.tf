# =============================================================================
# Azure DevOps Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Azure AD Authentication
# -----------------------------------------------------------------------------

output "project_id" {
  description = "ID of the target Azure DevOps project"
  value       = data.azuredevops_project.target.id
}

output "project_name" {
  description = "Name of the target Azure DevOps project"
  value       = data.azuredevops_project.target.name
}


# -----------------------------------------------------------------------------
# Section 1.2: Security Groups
# -----------------------------------------------------------------------------

output "security_reviewers_group_id" {
  description = "ID of the Security Reviewers group"
  value       = azuredevops_group.security_reviewers.id
}

output "security_reviewers_group_descriptor" {
  description = "Descriptor of the Security Reviewers group"
  value       = azuredevops_group.security_reviewers.descriptor
}


# -----------------------------------------------------------------------------
# Section 2.1: Workload Identity Federation
# -----------------------------------------------------------------------------

output "workload_identity_service_connection_id" {
  description = "ID of the workload identity federation service connection"
  value       = var.azure_subscription_id != "" ? azuredevops_serviceendpoint_azurerm.workload_identity[0].id : null
}

output "workload_identity_service_connection_name" {
  description = "Name of the workload identity federation service connection"
  value       = var.azure_subscription_id != "" ? azuredevops_serviceendpoint_azurerm.workload_identity[0].service_endpoint_name : null
}


# -----------------------------------------------------------------------------
# Section 3.2: Pipeline Environments
# -----------------------------------------------------------------------------

output "production_environment_id" {
  description = "ID of the production deployment environment"
  value       = azuredevops_environment.production.id
}

output "staging_environment_id" {
  description = "ID of the staging deployment environment"
  value       = azuredevops_environment.staging.id
}


# -----------------------------------------------------------------------------
# Section 3.3: Agent Pools
# -----------------------------------------------------------------------------

output "production_agent_pool_id" {
  description = "ID of the production agent pool"
  value       = azuredevops_agent_pool.production.id
}

output "production_agent_queue_id" {
  description = "ID of the production agent queue in the project"
  value       = azuredevops_agent_queue.production.id
}

output "security_agent_pool_id" {
  description = "ID of the security scanning agent pool (L2+ only)"
  value       = var.profile_level >= 2 ? azuredevops_agent_pool.security[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Branch Policies
# -----------------------------------------------------------------------------

output "branch_policy_min_reviewers_id" {
  description = "ID of the minimum reviewers branch policy"
  value       = var.repository_id != "" ? azuredevops_branch_policy_min_reviewers.main[0].id : null
}

output "branch_policy_comment_resolution_id" {
  description = "ID of the comment resolution branch policy"
  value       = var.repository_id != "" ? azuredevops_branch_policy_comment_resolution.main[0].id : null
}

output "branch_policy_work_item_linking_id" {
  description = "ID of the work item linking branch policy"
  value       = var.repository_id != "" ? azuredevops_branch_policy_work_item_linking.main[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Variable Groups
# -----------------------------------------------------------------------------

output "production_secrets_variable_group_id" {
  description = "ID of the production secrets variable group (Key Vault linked)"
  value       = var.key_vault_name != "" ? azuredevops_variable_group.production_secrets[0].id : null
}

output "shared_config_variable_group_id" {
  description = "ID of the shared configuration variable group"
  value       = azuredevops_variable_group.shared_config.id
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
    project_name                = var.project_name
    workload_identity_enabled   = var.azure_subscription_id != ""
    branch_policies_enabled     = var.repository_id != ""
    credential_scanning_enabled = var.repository_id != ""
    key_vault_linked            = var.key_vault_name != ""
    production_environment      = var.production_environment_name
    production_agent_pool       = var.agent_pool_name
    security_agent_pool         = var.profile_level >= 2 ? var.security_agent_pool_name : "not created (L2+)"
    pipeline_yaml_auto_review   = var.profile_level >= 2 && length(var.pipeline_yaml_reviewers) > 0
    business_hours_restriction  = var.profile_level >= 3
    exclusive_deploy_lock       = var.profile_level >= 2
  }
}
