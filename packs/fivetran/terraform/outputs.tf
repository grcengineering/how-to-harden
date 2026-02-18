# =============================================================================
# Fivetran Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 2.2: Team Structure (L2+)
# -----------------------------------------------------------------------------

output "team_ids" {
  description = "Map of team name to team ID (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in fivetran_team.teams : k => v.id } : {}
}


# -----------------------------------------------------------------------------
# Section 3.1: Connector Credentials
# -----------------------------------------------------------------------------

output "managed_connector_ids" {
  description = "Map of connector name to connector ID for managed connectors"
  value       = { for k, v in fivetran_connector.managed_connectors : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 3.3: Destination Security
# -----------------------------------------------------------------------------

output "destination_id" {
  description = "ID of the managed destination (if configured)"
  value       = length(fivetran_destination.primary) > 0 ? fivetran_destination.primary[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Activity Logging
# -----------------------------------------------------------------------------

output "activity_log_webhook_id" {
  description = "ID of the activity log webhook (if configured)"
  value       = length(fivetran_webhook.activity_log_webhook) > 0 ? fivetran_webhook.activity_log_webhook[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.2: Sync Monitoring
# -----------------------------------------------------------------------------

output "sync_failure_webhook_id" {
  description = "ID of the sync failure monitoring webhook (if configured)"
  value       = length(fivetran_webhook.sync_failure_webhook) > 0 ? fivetran_webhook.sync_failure_webhook[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.3: Data Governance (L2+)
# -----------------------------------------------------------------------------

output "column_blocking_connector_ids" {
  description = "Connector IDs with column blocking configured (L2+ only)"
  value       = var.profile_level >= 2 ? keys(var.blocked_columns) : []
}

output "column_hashing_connector_ids" {
  description = "Connector IDs with column hashing configured (L2+ only)"
  value       = var.profile_level >= 2 ? keys(var.hashed_columns) : []
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
    saml_sso_configured       = var.saml_idp_sso_url != ""
    saml_enforced             = var.profile_level >= 2 && var.sso_enforce_saml_only
    jit_provisioning          = var.profile_level >= 2 && var.jit_provisioning_enabled
    session_timeout_minutes   = var.session_timeout_minutes
    teams_configured          = var.profile_level >= 2 ? length(var.teams) : 0
    scim_provisioning         = var.profile_level >= 2
    managed_connectors        = length(var.connectors)
    network_security          = var.profile_level >= 2
    webhook_monitoring        = var.webhook_url != ""
    data_governance           = var.profile_level >= 2
    column_blocking_enabled   = var.profile_level >= 2 && length(var.blocked_columns) > 0
    column_hashing_enabled    = var.profile_level >= 2 && length(var.hashed_columns) > 0
  }
}
