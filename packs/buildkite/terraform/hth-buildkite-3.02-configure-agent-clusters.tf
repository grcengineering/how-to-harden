# =============================================================================
# HTH Buildkite Control 3.2: Configure Agent Clusters
# Profile Level: L2 (Hardened)
# Frameworks: CIS 13.5 | NIST AC-17
# Source: https://howtoharden.com/guides/buildkite/#32-configure-agent-clusters
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create isolated agent clusters per environment (L2+)
resource "buildkite_cluster" "clusters" {
  for_each = var.profile_level >= 2 ? var.clusters : {}

  name        = each.key
  description = each.value.description
  color       = each.value.color
  emoji       = each.value.emoji
}

# Create cluster queues for workload routing (L2+)
resource "buildkite_cluster_queue" "queues" {
  for_each = var.profile_level >= 2 ? var.cluster_queues : {}

  cluster_id  = buildkite_cluster.clusters[each.value.cluster_key].id
  key         = each.value.key
  description = each.value.description
}
# HTH Guide Excerpt: end terraform
