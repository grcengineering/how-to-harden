# =============================================================================
# Vercel Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

output "saml_enforced" {
  description = "Whether SAML SSO enforcement is active"
  value       = vercel_team_config.saml_enforcement.saml
}


# -----------------------------------------------------------------------------
# Section 1.2: Team Access Controls
# -----------------------------------------------------------------------------

output "team_members_configured" {
  description = "Map of team members and their assigned roles"
  value = {
    for k, v in vercel_team_member.members : k => {
      email = v.email
      role  = v.role
    }
  }
}


# -----------------------------------------------------------------------------
# Section 2.1: Secure Deployments
# -----------------------------------------------------------------------------

output "hardened_project_id" {
  description = "ID of the hardened Vercel project"
  value       = vercel_project.hardened.id
}

output "git_fork_protection" {
  description = "Whether Git fork protection is enabled"
  value       = vercel_project.hardened.git_fork_protection
}

output "preview_deployments_disabled" {
  description = "Whether preview deployments are disabled (L2+)"
  value       = vercel_project.hardened.preview_deployments_disabled
}


# -----------------------------------------------------------------------------
# Section 3.1: Environment Variables
# -----------------------------------------------------------------------------

output "environment_variables_configured" {
  description = "Keys of environment variables configured with security flags"
  value       = [for k, v in vercel_project_environment_variable.secrets : k]
}

output "sensitive_env_policy_enabled" {
  description = "Whether sensitive environment variable policy is enforced (L2+)"
  value       = var.profile_level >= 2
}


# -----------------------------------------------------------------------------
# Section 3.2: Access Token Security
# -----------------------------------------------------------------------------

output "trusted_ips_configured" {
  description = "Whether trusted IP allowlisting is configured (L2+)"
  value       = var.profile_level >= 2 && length(var.trusted_ip_addresses) > 0
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Log & Monitoring
# -----------------------------------------------------------------------------

output "log_drain_id" {
  description = "ID of the security log drain"
  value       = var.log_drain_endpoint != "" ? vercel_log_drain.security_logging[0].id : null
}

output "firewall_enabled" {
  description = "Whether the Web Application Firewall is enabled (L2+)"
  value       = var.profile_level >= 2 && var.firewall_enabled
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
    saml_enforced                = var.saml_enforced
    team_members_managed         = length(var.team_members) > 0
    git_fork_protection          = var.git_fork_protection_enabled
    preview_deployments_disabled = var.profile_level >= 2
    sensitive_env_policy         = var.profile_level >= 2 ? "enforced" : "default"
    trusted_ip_allowlisting      = var.profile_level >= 2 && length(var.trusted_ip_addresses) > 0
    log_drain_configured         = var.log_drain_endpoint != ""
    firewall_enabled             = var.profile_level >= 2 && var.firewall_enabled
    ip_privacy_hardening         = var.profile_level >= 2
    automation_bypass_disabled   = var.profile_level >= 3
  }
}
