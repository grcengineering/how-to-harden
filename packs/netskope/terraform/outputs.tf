# =============================================================================
# Netskope Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# Many Netskope controls use null_resource with REST API calls, so outputs
# reflect configuration state rather than resource IDs.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: Admin Console Access
# -----------------------------------------------------------------------------

output "admin_sso_configured" {
  description = "Whether SSO was configured for admin console access"
  value       = var.admin_sso_idp_entity_id != ""
}


# -----------------------------------------------------------------------------
# Section 1.2: Tenant Hardening
# -----------------------------------------------------------------------------

output "session_timeout_minutes" {
  description = "Admin console session timeout in minutes"
  value       = var.session_timeout_minutes
}

output "admin_ip_allowlist_enabled" {
  description = "Whether IP allowlisting is enabled for admin console (L2+)"
  value       = var.profile_level >= 2 && length(var.admin_ip_allowlist) > 0
}


# -----------------------------------------------------------------------------
# Section 2.2: Real-Time Protection Policies
# -----------------------------------------------------------------------------

output "unsanctioned_apps_blocked" {
  description = "Whether high-risk unsanctioned cloud apps are blocked"
  value       = var.block_unsanctioned_apps
}

output "personal_instances_blocked" {
  description = "Whether uploads to personal cloud instances are blocked"
  value       = var.block_personal_instances
}


# -----------------------------------------------------------------------------
# Section 2.3: API Protection (L2+)
# -----------------------------------------------------------------------------

output "api_protection_enabled" {
  description = "Whether API-enabled protection is configured (L2+ only)"
  value       = var.profile_level >= 2 && length(var.api_protection_apps) > 0
}

output "api_protection_apps" {
  description = "SaaS applications connected for API protection"
  value       = var.profile_level >= 2 ? var.api_protection_apps : []
}


# -----------------------------------------------------------------------------
# Section 3.1: DLP Profiles
# -----------------------------------------------------------------------------

output "dlp_detection_rules" {
  description = "Active DLP detection rule types"
  value       = local.dlp_detection_rules
}

output "dlp_advanced_enabled" {
  description = "Whether advanced DLP detection (EDM, fingerprinting, OCR, ML) is enabled (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 3.2: DLP Policy Enforcement
# -----------------------------------------------------------------------------

output "dlp_enforcement_action" {
  description = "DLP enforcement action based on profile level (alert/coach/block)"
  value       = local.dlp_action
}


# -----------------------------------------------------------------------------
# Section 4.1: Malware Protection
# -----------------------------------------------------------------------------

output "sandbox_enabled" {
  description = "Whether cloud sandboxing is enabled for unknown files"
  value       = var.sandbox_enabled
}

output "sandbox_file_types" {
  description = "File types submitted to cloud sandbox for analysis"
  value       = var.sandbox_enabled ? var.sandbox_file_types : []
}


# -----------------------------------------------------------------------------
# Section 4.2: Threat Protection Policies (L2+)
# -----------------------------------------------------------------------------

output "newly_registered_domains_blocked" {
  description = "Whether newly registered domains are blocked (L2+ only)"
  value       = var.profile_level >= 2 && var.block_newly_registered_domains
}

output "behavior_analytics_enabled" {
  description = "Whether cloud behavior analytics are enabled (L2+ only)"
  value       = var.profile_level >= 2 && var.enable_behavior_analytics
}


# -----------------------------------------------------------------------------
# Section 5.1: Client Steering
# -----------------------------------------------------------------------------

output "steering_mode" {
  description = "Traffic steering mode configured"
  value       = var.steering_mode
}

output "cert_pinned_exceptions_count" {
  description = "Number of certificate-pinned domains in Do Not Steer list"
  value       = length(var.cert_pinned_domains)
}


# -----------------------------------------------------------------------------
# Section 5.2: Client Deployment
# -----------------------------------------------------------------------------

output "fail_close_enabled" {
  description = "Whether fail-close mode is enabled on Netskope Client"
  value       = local.effective_fail_close
}

output "client_auto_update" {
  description = "Whether automatic client updates are enabled"
  value       = var.client_auto_update
}


# -----------------------------------------------------------------------------
# Section 6.1: Logging and Alerts
# -----------------------------------------------------------------------------

output "siem_integration_type" {
  description = "SIEM integration type configured (splunk/sentinel/syslog/none)"
  value       = var.siem_type
}

output "alerts_configured" {
  description = "Map of alert types and their enabled status"
  value = {
    dlp_violations     = var.alert_on_dlp_violations
    malware_detection  = var.alert_on_malware
    policy_violations  = var.alert_on_policy_violations
    admin_changes      = var.alert_on_admin_changes
  }
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
    admin_sso                   = var.admin_sso_idp_entity_id != ""
    admin_ip_allowlist          = var.profile_level >= 2 && length(var.admin_ip_allowlist) > 0
    session_timeout             = var.session_timeout_minutes
    unsanctioned_apps_blocked   = var.block_unsanctioned_apps
    personal_instances_blocked  = var.block_personal_instances
    api_protection              = var.profile_level >= 2 && length(var.api_protection_apps) > 0
    dlp_enforcement             = local.dlp_action
    dlp_advanced_detection      = var.profile_level >= 2
    malware_protection          = "enabled"
    cloud_sandbox               = var.sandbox_enabled
    newly_registered_blocked    = var.profile_level >= 2 && var.block_newly_registered_domains
    behavior_analytics          = var.profile_level >= 2 && var.enable_behavior_analytics
    steering_mode               = var.steering_mode
    fail_close                  = local.effective_fail_close
    siem_integration            = var.siem_type
  }
}
