# =============================================================================
# Twilio Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 2.2: Subaccounts (L2+)
# -----------------------------------------------------------------------------

output "subaccount_sids" {
  description = "SIDs of created subaccounts for environment isolation (L2+ only)"
  value       = var.profile_level >= 2 ? [for sa in twilio_api_accounts.subaccount : sa.sid] : []
}

output "subaccount_names" {
  description = "Friendly names of created subaccounts (L2+ only)"
  value       = var.profile_level >= 2 ? [for sa in twilio_api_accounts.subaccount : sa.friendly_name] : []
}


# -----------------------------------------------------------------------------
# Section 3.1: API Key Security
# -----------------------------------------------------------------------------

output "api_key_sid" {
  description = "SID of the hardened standard API key"
  value       = var.create_api_key ? twilio_api_accounts_keys.hardened_api_key[0].sid : null
}

output "api_key_secret" {
  description = "Secret of the hardened API key (shown only on creation)"
  value       = var.create_api_key ? twilio_api_accounts_keys.hardened_api_key[0].secret : null
  sensitive   = true
}

output "subaccount_api_key_sids" {
  description = "SIDs of per-subaccount API keys (L2+ only)"
  value       = var.profile_level >= 2 ? [for k in twilio_api_accounts_keys.subaccount_api_key : k.sid] : []
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
    profile_level        = var.profile_level
    l1_controls_applied  = true
    l2_controls_applied  = var.profile_level >= 2
    l3_controls_applied  = var.profile_level >= 3
    saml_sso             = var.sso_saml_issuer != "" ? "CONFIGURED" : "MANUAL"
    two_factor_auth      = "ENFORCED (manual)"
    user_roles           = "LEAST PRIVILEGE (manual)"
    admin_access         = "RESTRICTED (manual)"
    subaccounts          = var.profile_level >= 2 ? "${length(var.subaccounts)} created" : "not applicable"
    api_key_created      = var.create_api_key
    webhook_security     = var.profile_level >= 2 ? "ENFORCED" : "not applicable"
  }
}
