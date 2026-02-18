# =============================================================================
# Databricks Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.2: Service Principal Security
# -----------------------------------------------------------------------------

output "service_principal_ids" {
  description = "Map of service principal names to their Databricks application IDs"
  value       = { for k, v in databricks_service_principal.automation : k => v.application_id }
}


# -----------------------------------------------------------------------------
# Section 1.3: IP Access Lists (L2+)
# -----------------------------------------------------------------------------

output "ip_allowlist_id" {
  description = "ID of the corporate IP allowlist (L2+ only)"
  value       = var.profile_level >= 2 && length(var.allowed_ip_cidrs) > 0 ? databricks_ip_access_list.allow_corporate[0].id : null
}

output "ip_blocklist_id" {
  description = "ID of the blocked IP list (L2+ only)"
  value       = var.profile_level >= 2 && length(var.blocked_ip_cidrs) > 0 ? databricks_ip_access_list.block_bad_ips[0].id : null
}


# -----------------------------------------------------------------------------
# Section 3.1: Cluster Policies
# -----------------------------------------------------------------------------

output "hardened_cluster_policy_id" {
  description = "ID of the hardened cluster policy"
  value       = databricks_cluster_policy.hardened.id
}


# -----------------------------------------------------------------------------
# Section 3.2: Network Isolation (L2+)
# -----------------------------------------------------------------------------

output "network_isolation_policy_id" {
  description = "ID of the network isolation cluster policy (L2+ only)"
  value       = var.profile_level >= 2 ? databricks_cluster_policy.network_isolation[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Secret Scopes
# -----------------------------------------------------------------------------

output "secret_scope_names" {
  description = "List of created Databricks secret scope names"
  value       = [for k, v in databricks_secret_scope.managed : v.name]
}


# -----------------------------------------------------------------------------
# Section 4.2: External Secret Store (L2+)
# -----------------------------------------------------------------------------

output "azure_keyvault_scope_name" {
  description = "Name of the Azure Key Vault-backed secret scope (L2+ only)"
  value       = var.profile_level >= 2 && var.azure_keyvault_resource_id != "" ? databricks_secret_scope.azure_keyvault[0].name : null
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
    profile_level             = var.profile_level
    l1_controls_applied       = true
    l2_controls_applied       = var.profile_level >= 2
    l3_controls_applied       = var.profile_level >= 3
    sso_enforcement           = "configured"
    service_principals        = length(var.service_principals)
    ip_access_lists           = var.profile_level >= 2
    unity_catalog_governance  = "enabled"
    data_masking              = var.profile_level >= 2 ? "enabled" : "not_applied"
    audit_logging             = "enabled"
    cluster_policies          = "enforced"
    network_isolation         = var.profile_level >= 2 ? "enforced" : "not_applied"
    secret_scopes             = length(var.secret_scopes)
    external_secret_store     = var.profile_level >= 2 && var.azure_keyvault_resource_id != "" ? "azure_keyvault" : "not_configured"
    notebook_export_disabled  = var.profile_level >= 3
    results_download_disabled = var.profile_level >= 2
    security_monitoring       = "enabled"
  }
}
