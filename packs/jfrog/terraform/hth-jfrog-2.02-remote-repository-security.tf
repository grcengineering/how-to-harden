# =============================================================================
# HTH JFrog Control 2.2: Remote Repository Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7
# Source: https://howtoharden.com/guides/jfrog/#22-remote-repository-security
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Harden remote Maven repository proxy with security controls
resource "artifactory_remote_maven_repository" "secure_remote" {
  key                            = var.remote_repo_key
  url                            = var.remote_repo_url
  description                    = "HTH: Hardened remote repository proxy"
  store_artifacts_locally        = true
  hard_fail                      = true
  block_mismatching_mime_types   = true
  excludes_pattern               = var.blocked_remote_extensions
  xray_index                     = true
  content_synchronisation {
    enabled = false
  }
}

# L2: Enforce strict checksum validation on remote repositories
resource "artifactory_remote_maven_repository" "strict_checksum_remote" {
  count = var.profile_level >= 2 ? 1 : 0

  key                            = "${var.remote_repo_key}-strict"
  url                            = var.remote_repo_url
  description                    = "HTH: Strict checksum remote repository (L2+)"
  store_artifacts_locally        = true
  hard_fail                      = true
  block_mismatching_mime_types   = true
  excludes_pattern               = var.blocked_remote_extensions
  xray_index                     = true
  remote_repo_checksum_policy_type = "fail"
  content_synchronisation {
    enabled = false
  }
}

# HTH Guide Excerpt: end terraform
