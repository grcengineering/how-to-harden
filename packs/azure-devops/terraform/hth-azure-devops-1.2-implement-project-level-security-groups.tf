# =============================================================================
# HTH Azure DevOps Control 1.2: Implement Project-Level Security Groups
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/azure-devops/#12-implement-project-level-security-groups
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Create a dedicated Security Reviewers group for approval gates.
# Built-in groups (Project Administrators, Contributors, Build Administrators)
# are managed via the Azure DevOps UI. This creates the custom group used
# by service connection and environment approval controls.
# ---------------------------------------------------------------------------

resource "azuredevops_group" "security_reviewers" {
  scope        = data.azuredevops_project.target.id
  display_name = var.security_reviewers_group_name
  description  = "Security team members authorized to approve service connection usage and production deployments"
}

# Add members to the security reviewers group
resource "azuredevops_group_membership" "security_reviewers" {
  count = length(var.security_reviewer_members) > 0 ? 1 : 0

  group   = azuredevops_group.security_reviewers.descriptor
  mode    = "add"
  members = [for upn in var.security_reviewer_members : data.azuredevops_users.reviewers[upn].users[*].descriptor[0]]
}

# Look up each reviewer user by principal name
data "azuredevops_users" "reviewers" {
  for_each       = toset(var.security_reviewer_members)
  principal_name = each.value
}

# HTH Guide Excerpt: end terraform
