# =============================================================================
# Datadog Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SAML Single Sign-On
# -----------------------------------------------------------------------------

output "saml_sso_enabled" {
  description = "Whether SAML SSO is enabled on the organization"
  value       = datadog_organization_settings.saml_sso.settings[0].saml[0].enabled
}


# -----------------------------------------------------------------------------
# Section 1.2: SAML Strict Mode (L2+)
# -----------------------------------------------------------------------------

output "saml_strict_mode_enabled" {
  description = "Whether SAML strict mode is enforced (L2+ only)"
  value       = var.profile_level >= 2 ? datadog_organization_settings.saml_strict[0].settings[0].saml_strict_mode[0].enabled : null
}


# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

output "builtin_admin_role_id" {
  description = "ID of the built-in Datadog Admin role (for audit reference)"
  value       = data.datadog_role.admin.id
}

output "builtin_standard_role_id" {
  description = "ID of the built-in Datadog Standard role (for audit reference)"
  value       = data.datadog_role.standard.id
}

output "builtin_read_only_role_id" {
  description = "ID of the built-in Datadog Read Only role (for audit reference)"
  value       = data.datadog_role.read_only.id
}

output "custom_role_ids" {
  description = "Map of custom role names to their IDs"
  value       = { for k, v in datadog_role.custom : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 3.1: API Key Security
# -----------------------------------------------------------------------------

output "managed_api_key_ids" {
  description = "Map of managed API key names to their IDs"
  value       = { for k, v in datadog_api_key.managed : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 3.2: Application Key Security
# -----------------------------------------------------------------------------

output "managed_app_key_ids" {
  description = "Map of managed application key names to their IDs"
  value       = { for k, v in datadog_application_key.managed : k => v.id }
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
    saml_sso               = "enabled"
    saml_strict_mode       = var.profile_level >= 2 ? "enabled" : "not_applied"
    session_monitoring     = "enabled"
    rbac_custom_roles      = length(var.custom_roles)
    managed_api_keys       = length(var.api_key_names)
    managed_app_keys       = length(var.app_key_names)
    audit_monitoring       = "enabled"
    saml_change_detection  = var.profile_level >= 2 ? "enabled" : "not_applied"
  }
}
