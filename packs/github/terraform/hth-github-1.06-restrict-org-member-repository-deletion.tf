# =============================================================================
# HTH GitHub Control 1.06: Restrict Org Member Repository Deletion
# Profile Level: L3 (Run)
# Frameworks: NIST AC-6, MP-6
# Source: https://howtoharden.com/guides/github/#12-restrict-base-permissions-for-organization-members
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_settings" "repo_deletion" {
  billing_email                      = var.github_organization
  default_repository_permission      = "read"
  members_can_create_repositories    = false
}
# HTH Guide Excerpt: end terraform
