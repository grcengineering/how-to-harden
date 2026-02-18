# =============================================================================
# HTH Jenkins Control 2.1: Configure Matrix-Based Security
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/jenkins/#21-configure-matrix-based-security
#
# Creates team-isolated folders with project-based matrix authorization.
# The jenkins_folder resource supports security blocks for per-folder
# permission matrices, enforcing least-privilege access at the folder level.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Team-isolated folders with matrix authorization permissions
resource "jenkins_folder" "team_folder" {
  for_each = var.team_folders

  name         = each.key
  display_name = replace(title(each.key), "-", " ")
  description  = each.value.description

  dynamic "security" {
    for_each = length(each.value.permissions) > 0 ? [1] : []
    content {
      inheritance_strategy = "org.jenkinsci.plugins.matrixauth.inheritance.NonInheritingStrategy"
      permissions          = each.value.permissions
    }
  }
}

# JCasC for global matrix authorization strategy
resource "local_file" "matrix_authorization" {
  filename = "${path.module}/generated/casc-matrix-authorization.yaml"
  content  = yamlencode({
    jenkins = {
      authorizationStrategy = {
        projectMatrix = {
          permissions = concat(
            # Admin permissions
            [for user in var.admin_users : "Overall/Administer:${user}"],
            # Authenticated users get read-only by default
            [
              "Overall/Read:authenticated",
              "Job/Read:authenticated",
            ]
          )
        }
      }
    }
  })

  file_permission = "0644"
}
# HTH Guide Excerpt: end terraform
