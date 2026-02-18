# =============================================================================
# CrowdStrike Falcon Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 3.1: Sensor Anti-Tamper Protection
# -----------------------------------------------------------------------------

output "anti_tamper_windows_policy_id" {
  description = "ID of the Windows anti-tamper sensor update policy"
  value       = crowdstrike_sensor_update_policy.anti_tamper_windows.id
}

output "anti_tamper_linux_policy_id" {
  description = "ID of the Linux anti-tamper sensor update policy"
  value       = crowdstrike_sensor_update_policy.anti_tamper_linux.id
}

output "anti_tamper_mac_policy_id" {
  description = "ID of the Mac anti-tamper sensor update policy"
  value       = crowdstrike_sensor_update_policy.anti_tamper_mac.id
}


# -----------------------------------------------------------------------------
# Section 3.2: Prevention Policy Hardening
# -----------------------------------------------------------------------------

output "prevention_policy_windows_id" {
  description = "ID of the hardened Windows prevention policy"
  value       = crowdstrike_prevention_policy_windows.hardened.id
}

output "prevention_policy_linux_id" {
  description = "ID of the hardened Linux prevention policy"
  value       = crowdstrike_prevention_policy_linux.hardened.id
}

output "prevention_policy_mac_id" {
  description = "ID of the hardened Mac prevention policy"
  value       = crowdstrike_prevention_policy_mac.hardened.id
}


# -----------------------------------------------------------------------------
# Section 3.3: Host Group Strategy
# -----------------------------------------------------------------------------

output "canary_host_group_id" {
  description = "ID of the canary host group for staged deployments"
  value       = crowdstrike_host_group.canary.id
}

output "production_critical_host_group_id" {
  description = "ID of the production-critical host group"
  value       = crowdstrike_host_group.production_critical.id
}

output "production_standard_host_group_id" {
  description = "ID of the production-standard host group"
  value       = crowdstrike_host_group.production_standard.id
}

output "workstation_host_group_id" {
  description = "ID of the workstation host group"
  value       = crowdstrike_host_group.workstation.id
}

output "early_adopter_host_group_id" {
  description = "ID of the early-adopter host group (L2+ only)"
  value       = var.profile_level >= 2 ? crowdstrike_host_group.early_adopter[0].id : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Staged Content Deployment
# -----------------------------------------------------------------------------

output "content_policy_canary_id" {
  description = "ID of the canary ring content update policy"
  value       = crowdstrike_content_update_policy.canary.id
}

output "content_policy_early_adopter_id" {
  description = "ID of the early-adopter ring content update policy (L2+ only)"
  value       = var.profile_level >= 2 ? crowdstrike_content_update_policy.early_adopter[0].id : null
}

output "content_policy_production_id" {
  description = "ID of the production ring content update policy"
  value       = crowdstrike_content_update_policy.production.id
}

output "content_policy_production_critical_id" {
  description = "ID of the production-critical ring content update policy"
  value       = crowdstrike_content_update_policy.production_critical.id
}


# -----------------------------------------------------------------------------
# Section 4.2: Sensor Update Rollback
# -----------------------------------------------------------------------------

output "sensor_update_canary_policy_id" {
  description = "ID of the canary ring sensor update policy (L2+ only)"
  value       = var.profile_level >= 2 ? crowdstrike_sensor_update_policy.canary_ring[0].id : null
}

output "sensor_update_production_policy_id" {
  description = "ID of the production ring sensor update policy (L2+ only)"
  value       = var.profile_level >= 2 ? crowdstrike_sensor_update_policy.production_ring[0].id : null
}

output "sensor_update_critical_policy_id" {
  description = "ID of the critical infrastructure sensor update policy (L3 only)"
  value       = var.profile_level >= 3 ? crowdstrike_sensor_update_policy.critical_ring[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Detection Tuning - Response Policies
# -----------------------------------------------------------------------------

output "response_policy_windows_id" {
  description = "ID of the hardened Windows RTR policy"
  value       = crowdstrike_response_policy.hardened_windows.id
}

output "response_policy_linux_id" {
  description = "ID of the hardened Linux RTR policy"
  value       = crowdstrike_response_policy.hardened_linux.id
}

output "response_policy_mac_id" {
  description = "ID of the hardened Mac RTR policy"
  value       = crowdstrike_response_policy.hardened_mac.id
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
    profile_level                = var.profile_level
    l1_controls_applied          = true
    l2_controls_applied          = var.profile_level >= 2
    l3_controls_applied          = var.profile_level >= 3
    uninstall_protection         = var.uninstall_protection_enabled
    sensor_tamper_protection     = true
    prevention_windows_ml_level  = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention_linux_ml_level    = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    prevention_mac_ml_level      = var.profile_level >= 3 ? "EXTRA_AGGRESSIVE" : var.profile_level >= 2 ? "AGGRESSIVE" : "MODERATE"
    host_groups_created          = var.profile_level >= 2 ? 5 : 4
    content_update_rings         = var.profile_level >= 2 ? 4 : 3
    canary_delay_hours           = var.canary_content_delay_hours
    production_delay_hours       = var.production_content_delay_hours
    critical_delay_hours         = var.critical_content_delay_hours
    sensor_update_tiered         = var.profile_level >= 2
    rtr_custom_scripts           = var.profile_level >= 2
    rtr_exec_command             = var.profile_level >= 3
    memory_scanning              = var.profile_level >= 2
    driver_load_prevention       = var.profile_level >= 2
    container_drift_prevention   = var.profile_level >= 3
  }
}
