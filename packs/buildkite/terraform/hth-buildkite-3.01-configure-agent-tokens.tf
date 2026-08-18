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
# TRAP 5 — ROTATION TAKES TWO APPLIES, AND ONE APPLY STRANDS THE FLEET.
#   This pack used to rotate by forcing a replacement inside a single apply
#   (a `terraform_data` keeper plus `replace_triggered_by`). That is unsafe here,
#   and `create_before_destroy` does not rescue it. Chain the facts:
#     * TRAP 3 — the new secret is returned exactly ONCE, in this apply's output.
#     * So the operator cannot distribute it to the agent hosts until the apply
#       has already finished — by which point the incumbent token is destroyed.
#     * TRAP 1 of the companion api/ pack — revoking a token does NOT disconnect
#       agents that already registered with it.
#   The result is the worst detection profile available: nothing breaks at the
#   moment of the change. The fleet keeps running on connections it already holds
#   and quietly stops being able to REPLACE itself — the next host restart, the
#   next scale-out, the next spot reclaim fails to register, and the fleet
#   silently shrinks hours or days later.
#
#   ROTATION IS THEREFORE A TWO-PHASE, TWO-APPLY OPERATION, and it is encoded by
#   the shape of var.agent_tokens rather than by a keeper:
#
#     phase 1  ADD a new entry beside the incumbent — a new map key, same
#              cluster, same description, rotation_id bumped:
#                 prod_gen1 = { description = "prod agents", rotation_id = "1", ... }
#                 prod_gen2 = { description = "prod agents", rotation_id = "2", ... }
#              apply. Both tokens are now valid. Capture the new secret from the
#              output and put it in your secret manager.
#     phase 2  ROLL the agent hosts onto the new secret and confirm every host
#              has re-registered (the companion api/ pack's `audit`, or the
#              cluster's agent list in the console).
#     phase 3  REMOVE the old entry (`prod_gen1`) and apply again. The plan reads
#              "1 to destroy", which is the truth, and it is the only apply that
#              can strand anything — by which point nothing is using it.
#
#   EMERGENCY REVOCATION (leaked token) is the same act done deliberately:
#   delete the entry and apply. The plan says "1 to destroy" rather than
#   "1 to replace", so the responder reads what actually happens. Faster still is
#   the GraphQL path in api/hth-buildkite-3.01-agent-token-lifecycle.sh, which
#   also stops the agents the token registered — revocation on its own is not
#   containment.
#
#   CONSEQUENCE, STATED PLAINLY: editing `rotation_id` on an EXISTING entry no
#   longer mints anything. It is an in-place description update — it relabels the
#   incumbent token and rotates nothing. `rotation_id` is the generation marker
#   of the entry it is declared in; you set it when you add the entry and you
#   never edit it afterwards.
#
# Requires Terraform >= 1.5 / OpenTofu >= 1.6 (resource preconditions arrived in
# 1.4; the rotation `check` block below needs 1.5).
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
# Buildkite agent tokens have no server-side expiry that Terraform can set, so
# rotation on this surface is "mint a second token, move the fleet, delete the
# first". There is deliberately NO keeper resource and NO replace_triggered_by
# here: a same-apply replacement destroys the incumbent before the operator can
# possibly have distributed the replacement secret, which strands every host that
# has not yet re-registered (TRAP 5). Rotation is expressed by ADDING a map entry
# and, one apply later, REMOVING the old one — two applies, with the host roll in
# between, so the dangerous half is an explicit destroy the operator has read.
resource "buildkite_cluster_agent_token" "scoped_lifecycle" {
  for_each = var.agent_tokens

  cluster_id = data.buildkite_cluster.token_target[
    coalesce(each.value.cluster, var.agent_token_cluster_name)
  ].id

  # The description is the only human-readable handle on a token in the console
  # and in `GET /v2/organizations/{org}/clusters/{uuid}/tokens`. Stamping the
  # generation into it makes "which token are the agents actually presenting?"
  # answerable during an incident, and makes a two-phase rotation legible in the
  # console: during phase 2 you will see gen 1 and gen 2 side by side, which is
  # the state you are supposed to be in until every host has rolled.
  description = "${each.value.description} [hth-3.1 gen ${each.value.rotation_id}]"

  # CIDR allowlist. Empty list = unrestricted; the precondition below refuses to
  # plan that by default. A wrong CIDR is equally dangerous in the other
  # direction — agents outside it cannot register at all — so derive this from
  # your runners' observed egress addresses, not from the VPC block you assume
  # they use.
  allowed_ip_addresses = each.value.allowed_ip_addresses

  lifecycle {
    # Retained for any replacement the PROVIDER forces (changing cluster_id moves
    # the token to a different cluster, which cannot be done in place): the new
    # token is minted before the old one is destroyed. It is NOT a rotation
    # safety net — TRAP 5 — because the ordering it guarantees is within one
    # apply, and the gap that actually matters is the human one between reading
    # the new secret and every agent host presenting it.
    create_before_destroy = true

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

# Phase-2 reminder, not a guard — the destructive half of a rotation is the
# operator deleting a map entry, and nothing here should try to stop that. What
# this DOES catch is the half that fails silently: a rotation started and never
# finished, leaving the superseded token live and registerable indefinitely.
# Two entries sharing a cluster and a description are two generations of one
# token, which is the correct state during a roll and a finding afterwards.
check "agent_token_rotations_are_completed" {
  assert {
    condition = length(distinct([
      for k, t in var.agent_tokens :
      format("%s|%s", coalesce(t.cluster, var.agent_token_cluster_name), t.description)
      if length([
        for k2, t2 in var.agent_tokens : k2
        if coalesce(t2.cluster, var.agent_token_cluster_name) == coalesce(t.cluster, var.agent_token_cluster_name)
        && t2.description == t.description
      ]) > 1
    ])) == 0
    error_message = format(
      "Rotation in flight: %s. Two or more agent_tokens entries share a cluster and a description, so more than one generation of the same token is registerable. That is the CORRECT state during phase 2 of a rotation (both tokens valid while the agent hosts roll onto the new secret). It is a finding once the roll is done: confirm every host has re-registered, then delete the superseded entry and apply again. Revoking a token does not disconnect agents already connected with it, so a forgotten old generation is a live registration credential nobody is watching.",
      jsonencode({
        for k, t in var.agent_tokens :
        k => format("%s [gen %s] in %s", t.description, t.rotation_id, coalesce(t.cluster, var.agent_token_cluster_name))
        if length([
          for k2, t2 in var.agent_tokens : k2
          if coalesce(t2.cluster, var.agent_token_cluster_name) == coalesce(t.cluster, var.agent_token_cluster_name)
          && t2.description == t.description
        ]) > 1
      })
    )
  }
}
# HTH Guide Excerpt: end scope-restrict-and-rotate-tokens
