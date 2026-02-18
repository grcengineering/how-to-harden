# =============================================================================
# HTH JFrog Control 1.2: Implement Permission Targets
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/jfrog/#12-implement-permission-targets
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Production-Read: Read-only access for developers to release repositories
resource "artifactory_permission_target" "production_read" {
  name = "hth-production-read"

  repo {
    repositories = [var.release_repo_key]
    actions {
      groups {
        name        = var.release_readers_group
        permissions = ["read", "annotate"]
      }
    }
  }
}

# Production-Write: Deploy access restricted to release managers
resource "artifactory_permission_target" "production_write" {
  name = "hth-production-write"

  repo {
    repositories = [var.release_repo_key]
    actions {
      groups {
        name        = var.release_writers_group
        permissions = ["read", "annotate", "deploy", "delete"]
      }
    }
  }
}

# Build-Upload: CI/CD service accounts can deploy to snapshot repos only
resource "artifactory_permission_target" "build_upload" {
  name = "hth-build-upload"

  repo {
    repositories = [var.snapshot_repo_key]
    actions {
      groups {
        name        = var.ci_cd_group
        permissions = ["read", "deploy"]
      }
    }
  }
}

# L3: Strict read-only for all non-admin users on release repos
resource "artifactory_permission_target" "strict_readonly" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "hth-strict-readonly"

  repo {
    repositories = [var.release_repo_key]
    actions {
      groups {
        name        = var.release_readers_group
        permissions = ["read"]
      }
    }
  }
}

# HTH Guide Excerpt: end terraform
