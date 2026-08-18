# =============================================================================
# HTH Buildkite Control 2.1: Configure Team Permissions
# Profile Level: L1 (Crawl)
# Frameworks: CIS 5.4 | NIST AC-6
# Source: https://howtoharden.com/guides/buildkite/#21-configure-team-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create teams with least-privilege defaults
resource "buildkite_team" "teams" {
  for_each = var.teams

  name                = each.key
  description         = each.value.description
  privacy             = each.value.privacy
  default_team        = each.value.default_team
  default_member_role = each.value.default_member_role

  # All five members_can_* privileges are optional + COMPUTED. Declaring only one
  # of them, as this pack previously did, leaves the other four adopted from the
  # server on every refresh: a privilege granted in the console produces an empty
  # plan and is never reverted. Least privilege that Terraform cannot see is not
  # enforced, it is merely hoped for — so all five are declared here.
  members_can_create_pipelines  = each.value.members_can_create_pipelines
  members_can_create_registries = each.value.members_can_create_registries
  members_can_create_suites     = each.value.members_can_create_suites

  # DESTRUCTIVE PRIVILEGES — the two that were wholly unmanaged.
  # Package and registry deletion removes published artifacts and the registries
  # that hold them. Deletion is not an API-reversible operation, and a deleted
  # package takes its provenance and attestations with it, so this is the fastest
  # supply-chain-erasure path Buildkite exposes to a non-admin. Both default to
  # false in var.teams; granting either should be a reviewed, named exception.
  members_can_destroy_packages   = each.value.members_can_destroy_packages
  members_can_destroy_registries = each.value.members_can_destroy_registries
}
# HTH Guide Excerpt: end terraform
