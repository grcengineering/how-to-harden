# =============================================================================
# 1Password Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 3.1: Vault Permissions
# -----------------------------------------------------------------------------

output "infrastructure_vault_id" {
  description = "UUID of the Infrastructure vault"
  value       = data.onepassword_vault.infrastructure.uuid
}

output "team_shared_vault_id" {
  description = "UUID of the Team Shared vault"
  value       = data.onepassword_vault.team_shared.uuid
}

output "executive_vault_id" {
  description = "UUID of the Executive vault (L2+ only)"
  value       = var.profile_level >= 2 ? data.onepassword_vault.executive[0].uuid : null
}

output "security_vault_id" {
  description = "UUID of the Security vault (L2+ only)"
  value       = var.profile_level >= 2 ? data.onepassword_vault.security[0].uuid : null
}

output "break_glass_vault_id" {
  description = "UUID of the Break Glass vault (L3 only)"
  value       = var.profile_level >= 3 ? data.onepassword_vault.break_glass[0].uuid : null
}


# -----------------------------------------------------------------------------
# Section 1.2: SCIM Provisioning (L2+)
# -----------------------------------------------------------------------------

output "scim_bridge_config_id" {
  description = "UUID of the SCIM bridge configuration item (L2+ only)"
  value       = var.profile_level >= 2 && var.scim_bridge_url != "" ? onepassword_item.scim_bridge_config[0].uuid : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging / SIEM
# -----------------------------------------------------------------------------

output "siem_integration_config_id" {
  description = "UUID of the SIEM integration configuration item"
  value       = var.siem_endpoint != "" ? onepassword_item.siem_integration_config[0].uuid : null
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
    vaults_referenced = {
      infrastructure = true
      team_shared    = true
      executive      = var.profile_level >= 2
      security       = var.profile_level >= 2
      break_glass    = var.profile_level >= 3
    }
    sso_configured         = var.idp_sso_url != ""
    scim_configured        = var.profile_level >= 2 && var.scim_bridge_url != ""
    firewall_configured    = var.profile_level >= 2
    siem_configured        = var.siem_endpoint != ""
    password_policy        = var.profile_level >= 3 ? "Strict (14+)" : var.profile_level >= 2 ? "Medium (12+)" : "Minimum (10+)"
    sharing_policy         = var.profile_level >= 3 ? "Disabled or strict expiry" : var.profile_level >= 2 ? "Approval required" : "Default"
    dashboard_review       = var.profile_level >= 3 ? "Weekly" : var.profile_level >= 2 ? "Bi-weekly" : "Monthly"
  }
}
