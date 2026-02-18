# =============================================================================
# HTH Jenkins Control 2.2: Configure Project-Based Matrix Authorization
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/jenkins/#22-configure-project-based-matrix-authorization
#
# Extends folder-level security with non-inheriting permissions so each
# project folder has independent access controls. Requires the Matrix
# Authorization Strategy Plugin.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Project-isolated folders with strict non-inheriting permissions (L2+)
resource "jenkins_folder" "project_folder" {
  for_each = var.profile_level >= 2 ? var.project_folders : {}

  name         = each.key
  display_name = replace(title(each.key), "-", " ")
  description  = each.value.description
  folder       = each.value.parent_folder

  security {
    # Block permission inheritance so only explicitly granted users have access
    inheritance_strategy = "org.jenkinsci.plugins.matrixauth.inheritance.NonInheritingStrategy"
    permissions          = each.value.permissions
  }
}
# HTH Guide Excerpt: end terraform
