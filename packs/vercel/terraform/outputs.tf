# =============================================================================
# Vercel Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with SAML
# -----------------------------------------------------------------------------

output "saml_enforced" {
  description = "Whether SAML SSO enforcement is active"
  value       = vercel_team_config.saml_enforcement.saml
}


# -----------------------------------------------------------------------------
# Section 1.3: RBAC
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
# Section 2.1: Deployment Protection
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
# Section 3.1: WAF
# -----------------------------------------------------------------------------

output "firewall_enabled" {
  description = "Whether the Web Application Firewall is enabled"
  value       = var.firewall_enabled
}


# -----------------------------------------------------------------------------
# Section 4.2: Attack Challenge Mode
# -----------------------------------------------------------------------------

output "attack_challenge_mode" {
  description = "Whether Attack Challenge Mode is active"
  value       = var.attack_challenge_mode_enabled
}


# -----------------------------------------------------------------------------
# Section 6.1: Environment Variables
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
# Section 8.1: Log Drains
# -----------------------------------------------------------------------------

output "log_drain_id" {
  description = "ID of the security log drain"
  value       = var.log_drain_endpoint != "" ? vercel_log_drain.security_logging[0].id : null
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
    firewall_enabled             = var.firewall_enabled
    waf_owasp_action             = var.waf_owasp_action
    attack_challenge_mode        = var.attack_challenge_mode_enabled
    sensitive_env_policy         = var.profile_level >= 2 ? "enforced" : "default"
    trusted_ip_allowlisting      = var.profile_level >= 3 && length(var.trusted_ip_addresses) > 0
    secure_compute               = var.profile_level >= 3 && var.secure_compute_enabled
    log_drain_configured         = var.log_drain_endpoint != ""
    ip_privacy_hardening         = var.profile_level >= 2
  }
}
