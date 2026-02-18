# =============================================================================
# JFrog Hardening Code Pack - Outputs
# How to Harden (howtoharden.com)
#
# Outputs for verifying that hardening controls were applied correctly.
# =============================================================================


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

output "saml_sso_enabled" {
  description = "Whether SAML SSO is enabled"
  value       = artifactory_saml_settings.sso.enable
}

output "anonymous_access_disabled" {
  description = "Whether anonymous access is disabled"
  value       = !artifactory_general_security.disable_anonymous.enable_anonymous_access
}


# -----------------------------------------------------------------------------
# Section 1.2: Permission Targets
# -----------------------------------------------------------------------------

output "production_read_permission_name" {
  description = "Name of the production read permission target"
  value       = artifactory_permission_target.production_read.name
}

output "production_write_permission_name" {
  description = "Name of the production write permission target"
  value       = artifactory_permission_target.production_write.name
}

output "build_upload_permission_name" {
  description = "Name of the build upload permission target"
  value       = artifactory_permission_target.build_upload.name
}


# -----------------------------------------------------------------------------
# Section 1.3: API Key and Token Security
# -----------------------------------------------------------------------------

output "ci_cd_token_id" {
  description = "ID of the scoped CI/CD access token"
  value       = artifactory_scoped_token.ci_cd_token.id
}

output "ci_cd_token_expiry" {
  description = "Expiry duration of the CI/CD token in seconds"
  value       = artifactory_scoped_token.ci_cd_token.expires_in
}


# -----------------------------------------------------------------------------
# Section 2.1: Repository Layout Security
# -----------------------------------------------------------------------------

output "release_repo_key" {
  description = "Key of the hardened release repository"
  value       = artifactory_local_maven_repository.release.key
}

output "snapshot_repo_key" {
  description = "Key of the hardened snapshot repository"
  value       = artifactory_local_maven_repository.snapshot.key
}


# -----------------------------------------------------------------------------
# Section 2.2: Remote Repository Security
# -----------------------------------------------------------------------------

output "remote_repo_key" {
  description = "Key of the hardened remote repository"
  value       = artifactory_remote_maven_repository.secure_remote.key
}


# -----------------------------------------------------------------------------
# Section 2.3: Dependency Confusion Prevention
# -----------------------------------------------------------------------------

output "virtual_repo_key" {
  description = "Key of the virtual repository with priority resolution"
  value       = artifactory_virtual_maven_repository.secure_virtual.key
}


# -----------------------------------------------------------------------------
# Section 3.1: Artifact Signing (L2+)
# -----------------------------------------------------------------------------

output "gpg_keypair_name" {
  description = "Name of the GPG signing keypair (L2+ only)"
  value       = var.profile_level >= 2 ? artifactory_keypair.gpg_signing[0].pair_name : null
}


# -----------------------------------------------------------------------------
# Section 4.1: Xray Security Policies
# -----------------------------------------------------------------------------

output "xray_critical_policy_name" {
  description = "Name of the Xray critical CVE blocking policy"
  value       = artifactory_xray_security_policy.block_critical.name
}

output "xray_high_policy_name" {
  description = "Name of the Xray high CVE blocking policy (L2+ only)"
  value       = var.profile_level >= 2 ? artifactory_xray_security_policy.block_high[0].name : null
}

output "xray_watch_name" {
  description = "Name of the production Xray watch"
  value       = artifactory_xray_watch.production.name
}


# -----------------------------------------------------------------------------
# Section 4.2: License Compliance
# -----------------------------------------------------------------------------

output "license_policy_name" {
  description = "Name of the license compliance policy"
  value       = artifactory_xray_license_policy.license_compliance.name
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
    sso_enabled               = true
    anonymous_access          = "disabled"
    permission_targets        = "configured"
    repository_hardening      = "configured"
    dependency_confusion      = "mitigated"
    artifact_signing          = var.profile_level >= 2 ? "enabled" : "not_configured"
    immutable_artifacts       = var.profile_level >= 2 ? "enabled" : "not_configured"
    xray_critical_blocking    = "enabled"
    xray_high_blocking        = var.profile_level >= 2 ? "enabled" : "not_configured"
    audit_logging             = var.audit_webhook_url != "" ? "enabled" : "manual"
  }
}
