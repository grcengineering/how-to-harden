# =============================================================================
# HTH Buildkite Control 3.3: Secure Agent Infrastructure
# Profile Level: L2 (Walk)
# Frameworks: CIS 4.1 | NIST SC-7
# Source: https://howtoharden.com/guides/buildkite/#33-secure-agent-infrastructure
#
# Agents execute pipeline steps, so the agent boundary is where a poisoned
# pipeline becomes code running on your infrastructure. Clusters are the isolation
# primitive: a cluster-scoped token can only register agents into that cluster,
# so a leaked token cannot enroll an agent that picks up another team's jobs.
#
# TOKEN SCOPING — the reason this control exists.
# buildkite_agent_token (the legacy ORG-WIDE token, pack 3.1) is unavailable to
# organizations created after 2024-02-26 and is deliberately not used here. New
# work uses buildkite_cluster_agent_token, which is cluster-scoped.
#
# allowed_ip_addresses is a LOCKOUT-CAPABLE allowlist: an agent whose egress
# address is outside the list cannot register, and a wrong CIDR silently strands
# every agent in the cluster. Confirm your runners' egress addresses before
# applying, and leave var.agent_allowed_cidrs empty to skip the restriction
# rather than guessing at it.
#
# The complementary hardening — no-command-eval, no-local-hooks, redacted-vars —
# lives in the agent's own buildkite-agent.cfg, not in this provider. See the
# config/ pack for that half; neither half is sufficient alone.
# =============================================================================

# HTH Guide Excerpt: begin isolate-agent-clusters
# One cluster per trust boundary. Pipelines that handle production credentials do
# not share a cluster with pipelines that build untrusted contributor branches.
resource "buildkite_cluster" "isolated" {
  for_each = var.agent_clusters

  name        = each.key
  description = each.value.description
  emoji       = each.value.emoji
  color       = each.value.color
}

# Queues partition work WITHIN a cluster. dispatch_paused lets you stop a queue
# taking new jobs during an incident without deleting it and losing its config.
resource "buildkite_cluster_queue" "isolated" {
  for_each = var.agent_queues

  cluster_id      = buildkite_cluster.isolated[each.value.cluster].id
  key             = each.value.key
  description     = each.value.description
  dispatch_paused = each.value.paused
}
# HTH Guide Excerpt: end isolate-agent-clusters

# HTH Guide Excerpt: begin scope-agent-tokens
# Cluster-scoped registration tokens. A token leaked from one cluster cannot
# enroll an agent into another.
resource "buildkite_cluster_agent_token" "scoped" {
  for_each = var.agent_clusters

  cluster_id  = buildkite_cluster.isolated[each.key].id
  description = "HTH 3.3 — scoped registration token for cluster ${each.key}"

  # Empty list = no IP restriction. Set var.agent_allowed_cidrs only when you
  # know every runner's egress address; a wrong entry strands the whole cluster.
  allowed_ip_addresses = var.agent_allowed_cidrs
}

output "agent_cluster_tokens" {
  description = "Cluster registration tokens. Treat as credentials — write straight to your secret store, never to a log."
  sensitive   = true
  value = {
    for k, t in buildkite_cluster_agent_token.scoped : k => t.token
  }
}
# HTH Guide Excerpt: end scope-agent-tokens
