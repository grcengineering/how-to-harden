# =============================================================================
# HTH GitHub Control 7.03: Create Custom Repository Roles
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-2, AC-3
# Source: https://howtoharden.com/guides/github/#72-create-custom-repository-roles
#
# GitHub defines the fine-grained permission names. List them for your
# organization with GET /orgs/{org}/repository-fine-grained-permissions (the API
# pack for this section prints the security-related ones) and pass your choice
# in var.security_reviewer_permissions. Requires GitHub Enterprise Cloud.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_repository_role" "security_reviewer" {
  name        = "Security Reviewer"
  description = "Can view and triage security alerts"
  base_role   = "read"
  permissions = var.security_reviewer_permissions

  lifecycle {
    precondition {
      condition     = length(var.security_reviewer_permissions) > 0
      error_message = "Set security_reviewer_permissions to names returned by GET /orgs/{org}/repository-fine-grained-permissions."
    }
  }
}
# HTH Guide Excerpt: end terraform
