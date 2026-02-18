# =============================================================================
# HTH JFrog Control 2.3: Prevent Dependency Confusion
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-7
# Source: https://howtoharden.com/guides/jfrog/#23-prevent-dependency-confusion
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Virtual repository with internal repos resolved first to prevent
# dependency confusion attacks. Internal repositories take priority
# over external/remote repositories in the resolution order.
resource "artifactory_virtual_maven_repository" "secure_virtual" {
  key                                        = var.virtual_repo_key
  description                                = "HTH: Virtual repo with priority resolution to prevent dependency confusion"
  repositories                               = concat(var.internal_repo_keys, var.external_repo_keys)
  default_deployment_repo                    = var.internal_repo_keys[0]
  artifactory_requests_can_retrieve_remote_artifacts = true
  force_maven_authentication                 = true
}

# L2: Disable remote artifact retrieval through virtual repos
# to further isolate internal from external dependencies
resource "artifactory_virtual_maven_repository" "isolated_virtual" {
  count = var.profile_level >= 2 ? 1 : 0

  key                                        = "${var.virtual_repo_key}-isolated"
  description                                = "HTH: Isolated virtual repo - no remote retrieval (L2+)"
  repositories                               = var.internal_repo_keys
  default_deployment_repo                    = var.internal_repo_keys[0]
  artifactory_requests_can_retrieve_remote_artifacts = false
  force_maven_authentication                 = true
}

# HTH Guide Excerpt: end terraform
