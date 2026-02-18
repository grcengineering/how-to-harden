# =============================================================================
# HTH JFrog Control 2.1: Configure Repository Layout Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-7
# Source: https://howtoharden.com/guides/jfrog/#21-configure-repository-layout-security
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Harden local Maven release repository with restricted settings
resource "artifactory_local_maven_repository" "release" {
  key                   = var.release_repo_key
  description           = "HTH: Hardened release repository - handles releases only"
  handle_releases       = true
  handle_snapshots      = false
  suppress_pom_consistency_checks = false
  xray_index            = true
  property_sets         = ["artifactory"]
}

# Harden local Maven snapshot repository
resource "artifactory_local_maven_repository" "snapshot" {
  key                   = var.snapshot_repo_key
  description           = "HTH: Hardened snapshot repository - handles snapshots only"
  handle_releases       = false
  handle_snapshots      = true
  suppress_pom_consistency_checks = false
  xray_index            = true
  max_unique_snapshots  = 5
}

# HTH Guide Excerpt: end terraform
