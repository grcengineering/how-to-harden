# =============================================================================
# HTH Buildkite Control 3.1: Configure Agent Tokens
# Profile Level: L1 (Crawl)
# Frameworks: CIS 3.11 | NIST SC-12
# Source: https://howtoharden.com/guides/buildkite/#31-configure-agent-tokens
#
# WHAT CHANGED AND WHY.
# This pack previously used `buildkite_agent_token` — the UNCLUSTERED, deprecated
# resource. Control 3.2's own prose states that unclustered agent tokens are
# unavailable to organizations created after 2024-02-26, so the pack shipped a
# resource the guide itself declares dead. Every token here is now cluster-scoped
# through `buildkite_cluster_agent_token`, verified present in provider v1.38.0
# with exactly three writable attributes: cluster_id (required), description
# (required), allowed_ip_addresses (optional, list(string)).
#
# DIVISION OF LABOUR — read this before copying 3.1 and 3.3 together.
#   3.1 (this file) owns token LIFECYCLE and POLICY: which cluster a token binds
#     to, its IP allowlist, and forced rotation.
#   3.3 owns cluster ISOLATION: it CREATES clusters and queues and mints one
#     bootstrap token per cluster it creates.
#   They never collide, because this pack RESOLVES an existing cluster by name
#   (`data.buildkite_cluster`) rather than creating one. Both files can live in
#   the same directory and still plan cleanly.
#
# TRAP 1 — allowed_ip_addresses defaults to UNRESTRICTED.
#   Omitting the attribute is not "no opinion", it is "any source address on the
#   internet may register an agent with this token". Silence is the failure mode,
#   so the precondition below makes it loud: a token declared with an empty
#   allowlist fails the PLAN, before anything is created, unless the operator
#   explicitly sets var.agent_token_require_ip_allowlist = false.
#
# TRAP 2 — Terraform physically cannot set token expiry.
#   Verified against provider v1.38.0: `buildkite_cluster_agent_token` exposes no
#   `expires_at`. Expiry exists only on the GraphQL/REST create call. A token
#   created by this pack therefore NEVER EXPIRES, which is why rotation here is
#   modelled as forced replacement, and why the companion pack
#   `api/hth-buildkite-3.01-agent-token-lifecycle.sh` exists. Use that pack when
#   the control requires a time-bounded credential.
#
# TRAP 3 — the token value is readable exactly once.
#   `token` is computed + sensitive and is only returned by the create call. It
#   is persisted in state; treat the state file as a credential store and route
#   the output straight into a secret manager. Re-reading a token later is not
#   possible through any surface — the GraphQL ClusterToken type has no field
#   carrying the secret.
#
# TRAP 4 — the same setting has two different types on two surfaces.
#   allowed_ip_addresses is list(string) in Terraform but a single
#   space-separated String in GraphQL (ClusterAgentTokenCreateInput). Never copy
#   a literal between the .tf pack and the .sh pack.
#
# Requires Terraform >= 1.4 / OpenTofu >= 1.6 (`terraform_data`, preconditions).
# =============================================================================

# HTH Guide Excerpt: begin resolve-token-cluster
# Bind tokens to clusters that ALREADY EXIST rather than creating them here.
# A cluster is a trust boundary owned by control 3.3 (or by the console); token
# policy is a separate concern with a different change cadence, and coupling the
# two means every token rotation re-plans the cluster.
#
# `name` is the only selector this data source accepts, and it is case- and
# space-sensitive: Buildkite's auto-provisioned cluster is literally named
# "Default cluster". A typo surfaces as a plan-time "cluster not found", which is
# the desired failure — it is never silently created.
data "buildkite_cluster" "token_target" {
  for_each = toset([
    for token in var.agent_tokens :
    coalesce(token.cluster, var.agent_token_cluster_name)
  ])

  name = each.value
}
# HTH Guide Excerpt: end resolve-token-cluster

# HTH Guide Excerpt: begin scope-restrict-and-rotate-tokens
# Rotation keeper. Buildkite agent tokens have no server-side expiry that
# Terraform can set, so the only rotation primitive available in this surface is
# forced replacement. Bumping a token's `rotation_id` changes this object, which
# trips replace_triggered_by below and mints a NEW secret. Changing `description`
# alone would not: that is an in-place update (clusterAgentTokenUpdate) and the
# old secret would survive.
resource "terraform_data" "agent_token_rotation" {
  for_each = var.agent_tokens

  input = each.value.rotation_id
}

resource "buildkite_cluster_agent_token" "scoped_lifecycle" {
  for_each = var.agent_tokens

  cluster_id = data.buildkite_cluster.token_target[
    coalesce(each.value.cluster, var.agent_token_cluster_name)
  ].id

  # The description is the only human-readable handle on a token in the console
  # and in `GET /v2/organizations/{org}/clusters/{uuid}/tokens`. Stamping the
  # rotation generation into it makes "which token are the agents actually
  # presenting?" answerable during an incident.
  description = "${each.value.description} [hth-3.1 gen ${each.value.rotation_id}]"

  # CIDR allowlist. Empty list = unrestricted; the precondition below refuses to
  # plan that by default. A wrong CIDR is equally dangerous in the other
  # direction — agents outside it cannot register at all — so derive this from
  # your runners' observed egress addresses, not from the VPC block you assume
  # they use.
  allowed_ip_addresses = each.value.allowed_ip_addresses

  lifecycle {
    # Mint the replacement before destroying the incumbent, so a rotation does
    # not leave the cluster with no registerable token between apply steps.
    create_before_destroy = true

    replace_triggered_by = [terraform_data.agent_token_rotation[each.key]]

    precondition {
      condition = !var.agent_token_require_ip_allowlist || length(each.value.allowed_ip_addresses) > 0
      error_message = join(" ", [
        "Agent token '${each.key}' declares no allowed_ip_addresses.",
        "Buildkite treats an empty allowlist as UNRESTRICTED: the token would register an agent from any source address.",
        "Set allowed_ip_addresses to your runners' egress CIDRs, or set agent_token_require_ip_allowlist = false to accept the risk deliberately."
      ])
    }
  }
}
# HTH Guide Excerpt: end scope-restrict-and-rotate-tokens
