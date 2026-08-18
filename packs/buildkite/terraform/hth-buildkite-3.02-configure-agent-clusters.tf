# =============================================================================
# HTH Buildkite Control 3.2: Configure Agent Clusters
# Profile Level: L2 (Walk)
# Frameworks: CIS 13.5 | NIST AC-17
# Source: https://howtoharden.com/guides/buildkite/#32-configure-agent-clusters
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create isolated agent clusters per environment. Control 3.2 is an L2 control.
#
# NO PROFILE-LEVEL GATE ON for_each, DELIBERATELY. This line used to read
# `var.profile_level >= 2 ? var.clusters : {}`. var.profile_level defaults to 1,
# so a single `terraform apply` that omitted `-var="profile_level=2"` emptied the
# map and Terraform DESTROYED every cluster — and a cluster destroy takes its
# queues and its cluster-scoped agent tokens with it, which is the whole fleet's
# registration surface. Those token secrets are returned by the create call
# exactly once, so they are not recoverable from state. Profile level selects
# WHAT you declare; it must never decide whether declared resources survive.
# var.clusters defaults to `{}`, so declaring nothing is already the "off" state
# and is the only one.
resource "buildkite_cluster" "clusters" {
  for_each = var.clusters

  name        = each.key
  description = each.value.description
  color       = each.value.color
  emoji       = each.value.emoji

  lifecycle {
    # Dropping a key here, or renaming a cluster (the map key IS the name), is a
    # fleet-wide event: the queues and the cluster agent tokens go with it.
    # Refuse it at plan time rather than discovering it in an applied diff. To
    # retire a cluster on purpose: delete this line, apply, restore it.
    prevent_destroy = true
  }
}

# Create cluster queues for workload routing.
#
# Same reasoning as above: no profile gate. An empty var.cluster_queues — the
# default — is the off state. No prevent_destroy here, because a queue is
# recreatable from its key; note only that destroying one strands every agent
# configured to target that queue until it comes back.
resource "buildkite_cluster_queue" "queues" {
  for_each = var.cluster_queues

  cluster_id  = buildkite_cluster.clusters[each.value.cluster_key].id
  key         = each.value.key
  description = each.value.description
}
# HTH Guide Excerpt: end terraform
