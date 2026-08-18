# =============================================================================
# HTH Buildkite Control 3.7: Delegate Cluster Administration
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-6 (Least Privilege) | NIST AC-2 (Account Management)
# Source: https://howtoharden.com/guides/buildkite/#37-delegate-cluster-administration
#
# Pack 2.3 documents a hole it cannot close: the provider exposes no resource for
# organization-level roles, so the only way to let somebody manage a cluster's
# agent tokens, queues and secrets has historically been to make them a full
# organization admin - which also hands them SSO settings, billing, every other
# cluster, and the whole pipeline estate. Cluster maintainers are the scoped
# alternative. A maintainer administers one cluster and nothing else.
#
# WHAT A MAINTAINER ACTUALLY HOLDS - and why an unmanaged list undoes 3.2.
# Maintainer authority covers the cluster's agent registration tokens, its
# queues, and its SECRETS. Control 3.2 spends its whole budget making cluster A's
# agents unable to pick up cluster B's jobs; a maintainer added to cluster A in
# the console can mint a fresh registration token and read cluster A's secrets
# without appearing anywhere in that isolation model. The maintainer list is
# therefore part of the isolation boundary, not an administrative footnote, and
# it belongs under the same review as the cluster itself.
#
# TRAP 1 - EXACTLY ONE OF user_uuid / team_uuid. Both are `optional` in the
# schema; the constraint is a provider-side validator, so a config that sets both
# or neither is syntactically valid HCL that fails at plan. The precondition
# below turns that into a message naming the offending entry.
#
# TRAP 2 - `actor_type` IS COMPUTED. You do not declare whether a maintainer is a
# user or a team; Buildkite derives it from which UUID you supplied. Do not try
# to set it.
#
# TRAP 3 - PREFER TEAMS OVER INDIVIDUALS. A team maintainer re-evaluates against
# live team membership, so offboarding a person through the normal team process
# removes their cluster authority. A direct user maintainer survives every
# offboarding path except someone remembering this list. var.max_direct_user_
# maintainers defaults to 0 for that reason; raise it deliberately if you need a
# named break-glass individual.
#
# TRAP 4 - cluster_uuid IS THE UUID, NOT THE GRAPHQL ID. `buildkite_cluster` and
# `buildkite_cluster_queue` take the base64 GraphQL `id`; this resource takes the
# plain `uuid`. Feeding it `.id` fails. This pack resolves clusters by name
# through the data source and reads `.uuid` so the distinction cannot be got
# wrong by hand.
#
# Verification: provider schema introspected live (buildkite/buildkite v1.38.0 -
# cluster_uuid required, user_uuid/team_uuid optional, five computed actor_*
# attributes). The READ round-trip IS tenant-executed: `tofu plan` against the
# live organization read data.buildkite_cluster and returned maintainers = [] for
# cluster uuid 6a2b7f6a-2c31-49ef-a1b0-a3a675aaa10f, and REST
# GET /v2/organizations/{org}/clusters/{uuid}/maintainers returned HTTP 200. The
# WRITE round-trip was NOT executed - creating a maintainer is a privilege grant
# and this session was read-only - so buildkite_cluster_maintainer itself is
# schema- and vendor-doc-verified, not tenant-applied.
# =============================================================================

# HTH Guide Excerpt: begin delegate-cluster-administration
locals {
  # Every cluster this pack touches: the ones explicitly audited plus every
  # cluster named by a declared maintainer. Resolving by name keeps one source of
  # truth and yields the plain `uuid` the maintainer resource requires (TRAP 4).
  hth_governed_clusters = toset(concat(
    var.audited_clusters,
    [for m in var.cluster_maintainers : m.cluster],
  ))
}

data "buildkite_cluster" "governed" {
  for_each = local.hth_governed_clusters

  name = each.value
}

# Scoped cluster administration. Each entry replaces an organization-admin grant
# that would otherwise have been issued just to manage one cluster's tokens,
# queues and secrets.
resource "buildkite_cluster_maintainer" "delegated" {
  for_each = var.cluster_maintainers

  cluster_uuid = data.buildkite_cluster.governed[each.value.cluster].uuid

  # Exactly one of these is non-null. Teams are the default shape; see TRAP 3.
  team_uuid = each.value.team_uuid
  user_uuid = each.value.user_uuid

  lifecycle {
    # TRAP 1. Surface the exactly-one-of constraint with the entry's key in it.
    precondition {
      condition     = (each.value.team_uuid == null) != (each.value.user_uuid == null)
      error_message = format("Maintainer '%s' must set exactly one of team_uuid or user_uuid. A team is preferred: team membership changes revoke cluster authority automatically, a direct user grant does not.", each.key)
    }
  }
}

# TRAP 3, enforced. Direct user maintainers are the grants that outlive
# offboarding, so the count is bounded and the bound is zero by default.
check "direct_user_maintainers_within_bound" {
  assert {
    condition = length([for m in var.cluster_maintainers : m if m.user_uuid != null]) <= var.max_direct_user_maintainers
    error_message = format(
      "%d cluster maintainers are individual users; at most %d are permitted. Grant cluster administration to a team_uuid instead, or raise var.max_direct_user_maintainers deliberately to record a break-glass individual.",
      length([for m in var.cluster_maintainers : m if m.user_uuid != null]),
      var.max_direct_user_maintainers,
    )
  }
}

output "cluster_maintainer_grants" {
  description = "Every declared cluster administration grant as Buildkite resolved it. actor_type is computed - it reflects which UUID was supplied, not a declaration."
  value = {
    for k, m in buildkite_cluster_maintainer.delegated : k => {
      cluster      = var.cluster_maintainers[k].cluster
      cluster_uuid = m.cluster_uuid
      actor_type   = m.actor_type
      actor_name   = m.actor_name
      actor_slug   = m.actor_slug
      actor_uuid   = m.actor_uuid
    }
  }
}
# HTH Guide Excerpt: end delegate-cluster-administration

# HTH Guide Excerpt: begin audit-cluster-maintainers
# The write half above only governs the grants Terraform made. The boundary risk
# is the grant somebody added in the console. data.buildkite_cluster returns the
# live maintainer list for a cluster, so drift is detectable without a resource.
locals {
  # Actors approved to administer a cluster: everyone this configuration grants,
  # plus any UUID explicitly accepted as pre-existing.
  hth_approved_maintainer_uuids = toset(concat(
    [for m in var.cluster_maintainers : coalesce(m.team_uuid, m.user_uuid)],
    var.additional_approved_maintainer_uuids,
  ))

  # Live maintainers across every governed cluster, flattened for comparison.
  hth_live_maintainers = flatten([
    for name, c in data.buildkite_cluster.governed : [
      for m in c.maintainers : {
        cluster    = name
        actor_type = m.actor_type
        actor_uuid = m.actor_uuid
        actor_name = m.actor_name
      }
    ]
  ])

  hth_unapproved_maintainers = [
    for m in local.hth_live_maintainers : m
    if !contains(local.hth_approved_maintainer_uuids, m.actor_uuid)
  ]
}

# Continuous validation: reports on every plan and apply, does not block. An
# unapproved maintainer is a review finding about who can mint agent tokens and
# read cluster secrets - surface it every run rather than failing an unrelated
# deploy at 2am.
check "no_unapproved_cluster_maintainers" {
  assert {
    condition = length(local.hth_unapproved_maintainers) == 0
    error_message = format(
      "%d cluster maintainer(s) are not declared in Terraform and hold agent-token, queue and secret authority over their cluster: %s. Either declare them in var.cluster_maintainers, accept them in var.additional_approved_maintainer_uuids, or remove them in the Buildkite console.",
      length(local.hth_unapproved_maintainers),
      jsonencode(local.hth_unapproved_maintainers),
    )
  }
}

output "cluster_maintainer_audit" {
  description = "Live maintainer roster for every governed cluster, and the subset holding authority without a Terraform declaration."
  value = {
    live       = local.hth_live_maintainers
    unapproved = local.hth_unapproved_maintainers
  }
}
# HTH Guide Excerpt: end audit-cluster-maintainers
