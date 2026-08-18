# =============================================================================
# HTH Buildkite Control 2.3: Limit Administrative Access
# Profile Level: L1 (Crawl)
# Frameworks: CIS 5.4 | NIST AC-6
# Source: https://howtoharden.com/guides/buildkite/#23-limit-administrative-access
#
# This is a VERIFICATION pack. It reads the organization's real membership and
# team role assignments so drift is visible in `terraform plan`; it does not
# grant or revoke org-level admin, because the provider offers no resource that
# does (enumerated from the live provider schema: 21 resources, none of them an
# organization-member role).
#
# HONEST LIMITATION — read before relying on this.
# The buildkite_organization_members data source returns email, id, name, and
# uuid for each member. It does NOT return the member's organization ROLE, so
# Terraform alone cannot tell you who the admins are. Org-level role lives in
# GraphQL (organization.members.edges.node.role, mutated by
# organizationMemberUpdate). Use this pack for roster and team-role drift; use
# the GraphQL query in pack 1.01's api/ file as the model for a true admin census.
#
# What IS enforceable here: team-scoped roles, via buildkite_team_member.role.
# =============================================================================

# HTH Guide Excerpt: begin audit-membership
# The full organization roster. Surfaces joiners and leavers as plan diffs.
data "buildkite_organization_members" "all" {}

# Assert the roster has not grown past the size you reviewed. A bare count is a
# weak control on its own, but it turns silent membership growth into a failed
# plan, which is the point.
check "membership_within_expected_size" {
  assert {
    condition = length(data.buildkite_organization_members.all.members) <= var.max_org_members
    error_message = format(
      "Organization has %d members, expected at most %d. Review the roster and either remove members or raise max_org_members deliberately.",
      length(data.buildkite_organization_members.all.members),
      var.max_org_members,
    )
  }
}

output "organization_roster" {
  description = "Every organization member (role is NOT exposed by this data source — see header)."
  value = [
    for m in data.buildkite_organization_members.all.members : {
      name  = m.name
      email = m.email
      uuid  = m.uuid
    }
  ]
}
# HTH Guide Excerpt: end audit-membership

# HTH Guide Excerpt: begin restrict-team-admins
# Team-scoped roles ARE manageable. Declaring maintainers explicitly means an
# out-of-band promotion in the console shows up as drift on the next plan.
resource "buildkite_team_member" "maintainers" {
  for_each = var.team_maintainers

  team_id = each.value.team_id
  user_id = each.value.user_id
  role    = "MAINTAINER"
}

resource "buildkite_team_member" "members" {
  for_each = var.team_members

  team_id = each.value.team_id
  user_id = each.value.user_id
  role    = "MEMBER"
}
# HTH Guide Excerpt: end restrict-team-admins
