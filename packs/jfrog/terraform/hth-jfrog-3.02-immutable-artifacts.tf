# =============================================================================
# HTH JFrog Control 3.2: Immutable Artifacts
# Profile Level: L2 (Hardened)
# Frameworks: NIST SI-7
# Source: https://howtoharden.com/guides/jfrog/#32-immutable-artifacts
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Immutable release repository: block re-deployment of existing versions (L2+)
# Once an artifact version is published, it cannot be overwritten.
resource "artifactory_local_maven_repository" "immutable_release" {
  count = var.profile_level >= 2 ? 1 : 0

  key                             = "${var.release_repo_key}-immutable"
  description                     = "HTH: Immutable release repository - no redeployment (L2+)"
  handle_releases                 = true
  handle_snapshots                = false
  suppress_pom_consistency_checks = false
  xray_index                      = true

  # Block re-deployment to enforce immutability
  # Users cannot overwrite existing artifact versions
}

# L3: Restrict delete permissions to prevent artifact removal
resource "artifactory_permission_target" "immutable_no_delete" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "hth-immutable-no-delete"

  repo {
    repositories = ["${var.release_repo_key}-immutable"]
    actions {
      groups {
        name        = var.release_readers_group
        permissions = ["read"]
      }
      groups {
        name        = var.release_writers_group
        permissions = ["read", "annotate", "deploy"]
      }
    }
  }
}

# HTH Guide Excerpt: end terraform
