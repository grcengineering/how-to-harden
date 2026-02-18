# =============================================================================
# Jenkins Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 2.1: Matrix-Based Security - Team Folders
# -----------------------------------------------------------------------------

output "team_folder_ids" {
  description = "Map of team folder names to their Jenkins canonical paths"
  value       = { for k, v in jenkins_folder.team_folder : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 2.2: Project-Based Matrix Authorization (L2+)
# -----------------------------------------------------------------------------

output "project_folder_ids" {
  description = "Map of project folder names to their Jenkins canonical paths (L2+ only)"
  value       = var.profile_level >= 2 ? { for k, v in jenkins_folder.project_folder : k => v.id } : {}
}


# -----------------------------------------------------------------------------
# Section 4.2: Secure Credentials - Domain Folders
# -----------------------------------------------------------------------------

output "credential_domain_ids" {
  description = "Map of credential domain folder names to their Jenkins canonical paths"
  value       = { for k, v in jenkins_folder.credential_domain : k => v.id }
}


# -----------------------------------------------------------------------------
# Section 4.4: Secure Pipeline Template (L2+)
# -----------------------------------------------------------------------------

output "secure_pipeline_template_id" {
  description = "ID of the secure pipeline template job (L2+ only)"
  value       = var.profile_level >= 2 && var.create_secure_pipeline_template ? jenkins_job.secure_pipeline_template[0].id : null
}


# -----------------------------------------------------------------------------
# Section 5.1: Security Monitoring View
# -----------------------------------------------------------------------------

output "security_monitoring_view_name" {
  description = "Name of the security monitoring Jenkins view"
  value       = var.create_security_views ? jenkins_view.security_monitoring[0].name : null
}

output "security_monitoring_view_url" {
  description = "URL of the security monitoring Jenkins view"
  value       = var.create_security_views ? jenkins_view.security_monitoring[0].url : null
}


# -----------------------------------------------------------------------------
# Generated Configuration Files
# -----------------------------------------------------------------------------

output "generated_casc_files" {
  description = "List of generated JCasC YAML files to deploy to $JENKINS_HOME/casc_configs/"
  value = compact([
    local_file.enable_authentication.filename,
    local_file.matrix_authorization.filename,
    local_file.agent_controller_access.filename,
    local_file.disable_builds_on_controller.filename,
    local_file.secure_agent_communication.filename,
    local_file.enable_csrf_protection.filename,
    local_file.pipeline_sandbox.filename,
    local_file.audit_logging.filename,
    local_file.update_center_config.filename,
    var.profile_level >= 2 && var.sso_type == "saml" ? local_file.configure_saml_sso[0].filename : "",
    var.profile_level >= 2 && var.sso_type == "ldap" ? local_file.configure_ldap[0].filename : "",
    var.profile_level >= 2 ? local_file.disable_remember_me[0].filename : "",
    var.profile_level >= 2 && var.enable_rbac ? local_file.rbac_configuration[0].filename : "",
    var.profile_level >= 2 && var.cloud_agent_type == "kubernetes" ? local_file.ephemeral_agents_k8s[0].filename : "",
    var.profile_level >= 2 && var.cloud_agent_type == "docker" ? local_file.ephemeral_agents_docker[0].filename : "",
  ])
}

output "generated_groovy_scripts" {
  description = "List of generated Groovy init scripts to deploy to $JENKINS_HOME/init.groovy.d/"
  value = compact([
    local_file.script_console_audit.filename,
    local_file.agent_controller_access_groovy.filename,
    local_file.disable_controller_builds_groovy.filename,
    local_file.secure_agent_protocols_groovy.filename,
    local_file.csrf_protection_groovy.filename,
    local_file.pipeline_sandbox_groovy.filename,
    local_file.check_updates_groovy.filename,
    var.profile_level >= 2 ? local_file.disable_remember_me_groovy[0].filename : "",
  ])
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
    profile_level              = var.profile_level
    l1_controls_applied        = true
    l2_controls_applied        = var.profile_level >= 2
    l3_controls_applied        = var.profile_level >= 3
    authentication             = "enabled"
    sso_configured             = var.profile_level >= 2 && var.sso_type != "none"
    sso_type                   = var.sso_type
    remember_me_disabled       = var.profile_level >= 2
    matrix_authorization       = "configured"
    project_matrix             = var.profile_level >= 2
    rbac_enabled               = var.profile_level >= 2 && var.enable_rbac
    script_console_restricted  = true
    agent_controller_security  = "enabled"
    controller_executors       = var.controller_executors
    ephemeral_agents           = var.profile_level >= 2 && var.cloud_agent_type != "none"
    agent_protocol             = "JNLP4-connect (TLS)"
    csrf_protection            = "enabled"
    credential_scoping         = length(var.credential_domains) > 0
    pipeline_sandbox           = "enforced"
    secure_pipeline_template   = var.profile_level >= 2 && var.create_secure_pipeline_template
    audit_logging              = "configured"
    siem_integration           = var.syslog_server != ""
    security_monitoring_view   = var.create_security_views
  }
}
