# =============================================================================
# CyberArk Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: MFA Configuration
# -----------------------------------------------------------------------------

output "mfa_radius_configured" {
  description = "Whether RADIUS MFA integration was configured"
  value       = var.mfa_radius_server != "" ? true : false
}


# -----------------------------------------------------------------------------
# Section 1.2: Vault-Level Access Controls
# -----------------------------------------------------------------------------

output "safes_created" {
  description = "List of safes created with access controls"
  value       = keys(var.safes)
}

output "safe_members_configured" {
  description = "List of safe member assignments configured"
  value       = keys(var.safe_members)
}

output "dual_control_enabled" {
  description = "Whether dual-control approval is enabled (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 1.3: Break-Glass Procedures
# -----------------------------------------------------------------------------

output "break_glass_safe_name" {
  description = "Name of the break-glass emergency safe"
  value       = var.break_glass_safe_name
}

output "break_glass_enhanced" {
  description = "Whether enhanced break-glass controls are enabled (L3)"
  value       = var.profile_level >= 3
}


# -----------------------------------------------------------------------------
# Section 2.1: Vault Server Hardening
# -----------------------------------------------------------------------------

output "tls_minimum_version" {
  description = "Minimum TLS version enforced"
  value       = var.profile_level >= 3 ? "1.3" : "1.2"
}


# -----------------------------------------------------------------------------
# Section 2.2: Vault High Availability
# -----------------------------------------------------------------------------

output "vault_ha_enabled" {
  description = "Whether vault HA verification is enabled (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 3.1: API Authentication
# -----------------------------------------------------------------------------

output "api_ip_restrictions_enabled" {
  description = "Whether API IP restrictions are configured"
  value       = length(var.api_allowed_ips) > 0
}

output "api_token_policy" {
  description = "API token expiration policy applied"
  value = var.profile_level >= 3 ? "single-use-30min" : (
    var.profile_level >= 2 ? "short-lived-60min" : "default"
  )
}


# -----------------------------------------------------------------------------
# Section 3.2: Integration Permissions
# -----------------------------------------------------------------------------

output "integration_users_configured" {
  description = "List of integration service accounts configured"
  value       = keys(var.integration_users)
}

output "integration_audit_enabled" {
  description = "Whether detailed integration audit logging is enabled (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 3.3: External Secrets Integration
# -----------------------------------------------------------------------------

output "external_secrets_integration" {
  description = "Whether external secrets manager integrations are configured (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 4.1: PSM Session Security
# -----------------------------------------------------------------------------

output "session_recording_enabled" {
  description = "Whether PSM session recording is enabled"
  value       = var.session_recording_enabled
}

output "session_max_duration" {
  description = "Maximum PSM session duration in minutes"
  value       = var.profile_level >= 2 ? 240 : var.session_max_duration_minutes
}

output "session_idle_timeout" {
  description = "PSM session idle timeout in minutes"
  value       = var.profile_level >= 2 ? 15 : var.session_idle_timeout_minutes
}


# -----------------------------------------------------------------------------
# Section 4.2: Just-In-Time Access
# -----------------------------------------------------------------------------

output "jit_access_enabled" {
  description = "Whether just-in-time access is enabled (L2+)"
  value       = var.profile_level >= 2
}

output "jit_time_boxed" {
  description = "Whether time-boxed JIT access with dual approval is enforced (L3)"
  value       = var.profile_level >= 3
}


# -----------------------------------------------------------------------------
# Section 5.1: Password Rotation
# -----------------------------------------------------------------------------

output "password_rotation_interval_days" {
  description = "Password rotation interval in days"
  value = var.profile_level >= 3 ? 1 : (
    var.profile_level >= 2 ? 7 : var.password_rotation_days
  )
}

output "password_min_length_applied" {
  description = "Minimum password length enforced"
  value       = var.password_min_length
}


# -----------------------------------------------------------------------------
# Section 5.2: Rotation Failure Monitoring
# -----------------------------------------------------------------------------

output "auto_reconcile_on_failure" {
  description = "Whether automatic reconciliation on failure is enabled (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 6.1: Audit Logging
# -----------------------------------------------------------------------------

output "siem_forwarding_enabled" {
  description = "Whether SIEM log forwarding is configured"
  value       = var.siem_server != ""
}

output "enhanced_detection_enabled" {
  description = "Whether enhanced detection use cases are enabled (L2+)"
  value       = var.profile_level >= 2
}

output "forensic_logging_enabled" {
  description = "Whether forensic logging with immutable audit trail is enabled (L3)"
  value       = var.profile_level >= 3
}

output "audit_retention_days" {
  description = "Audit log retention period in days"
  value       = var.profile_level >= 3 ? 730 : var.audit_retention_days
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
    mfa_configured              = var.mfa_radius_server != ""
    safes_created               = length(var.safes)
    break_glass_safe            = var.break_glass_safe_name
    tls_minimum                 = var.profile_level >= 3 ? "1.3" : "1.2"
    vault_ha                    = var.profile_level >= 2 ? "verified" : "not_checked"
    api_ip_restrictions         = length(var.api_allowed_ips) > 0
    api_token_policy            = var.profile_level >= 3 ? "single-use" : (var.profile_level >= 2 ? "short-lived" : "default")
    integration_audit           = var.profile_level >= 2
    external_secrets_integration = var.profile_level >= 2
    session_recording           = var.session_recording_enabled
    jit_access                  = var.profile_level >= 2
    password_rotation_days      = var.profile_level >= 3 ? 1 : (var.profile_level >= 2 ? 7 : var.password_rotation_days)
    siem_forwarding             = var.siem_server != ""
    enhanced_detection          = var.profile_level >= 2
    forensic_logging            = var.profile_level >= 3
  }
}
