# =============================================================================
# HTH Buildkite Control 3.5: Manage Build Secrets — cluster secrets + policies
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-12, SC-28
# Source: https://howtoharden.com/guides/buildkite/#35-manage-build-secrets
#
# Control 3.5 ships no pack at all today, and the two halves it needs are the two
# halves Terraform is unusually good at: putting the secret somewhere the agent
# host cannot harvest it, and writing down which builds may read it.
#
# ── WHY value_wo IS THE WHOLE POINT ──────────────────────────────────────────
# buildkite_cluster_secret takes EXACTLY ONE of `value` or `value_wo`. `value` is
# marked sensitive, which controls how Terraform PRINTS it — it is still written
# verbatim into terraform.tfstate and into any saved plan file. A team that moves
# its deploy key out of an agent host env var and into `value` has moved it into
# a state file that typically lives in a bucket more people can read than could
# ever have logged into the agent. `value_wo` is `write_only` in the provider
# schema: the value is sent to the API and is never persisted to plan or state.
# That ephemeral path IS the hardening story of this pack, not an optimisation.
#
# ── ⚠️ VERSION FLOOR: this file needs Terraform >= 1.11 / OpenTofu >= 1.11 ───
# Two separate keywords, two separate floors, and this file uses both:
#   `value_wo` (write-only arguments) — Terraform 1.11.0, OpenTofu 1.11.0.
#   `ephemeral = true` on an input variable — Terraform 1.10.0, OpenTofu 1.11.0.
# providers.tf in this directory declares `required_version = ">= 1.5"`, which is
# the floor for the OTHER packs and is NOT sufficient here. Raise it in
# providers.tf before applying this file:
#     required_version = ">= 1.11"   # value_wo + ephemeral (control 3.5)
#
# It is left unedited so adopting one pack does not silently raise the toolchain
# floor for every other control in the directory — and that promise is only true
# if NOTHING SHARED uses a 1.10+ keyword. It previously was not: the ephemeral
# `var.cluster_secret_values` sat in the shared variables.tf, so `tofu validate`
# on a 1.5 toolchain failed for every pack in the directory, including ones that
# never touch a secret. That declaration now lives in THIS file, below, where the
# floor it imposes is the floor of the pack that imposes it.
#
# ── ⚠️ TRAP 1: sensitive maps cannot drive for_each ──────────────────────────
# The instinct is one map of {key = secret_value} marked `sensitive = true`.
# Terraform rejects it: "Sensitive values, or values derived from sensitive
# values, cannot be used as for_each arguments" — because the map's KEYS become
# resource addresses, which are written to state in clear. The shape below is the
# fix and not a workaround: metadata (cluster, version, policy) lives in a plain
# non-sensitive map that drives for_each, and the values live in a SEPARATE
# ephemeral map that is only ever indexed inside the resource body. Protection
# comes from value_wo, not from decorating the iterator.
#
# ── ⚠️ TRAP 2: value_wo_version is a STRING, and it is the update trigger ────
# Two mistakes, one attribute. It is `"type": "string"` in the schema, so
# value_wo_version = 2 fails; it must be "2". And because Terraform cannot see a
# write-only value, changing the secret ALONE produces no diff — the rotated
# credential never reaches Buildkite and the plan says "No changes". The version
# marker is the only thing Terraform compares. Rotate = new value AND bumped
# version, together. Feeding it the upstream secret manager's own version id
# (AWS Secrets Manager VersionId, Vault version number) makes that automatic.
#
# ── ⚠️ TRAP 3: cluster_id here is the UUID — the SAME NAME means something
#      different one resource over ────────────────────────────────────────────
# Provider schema descriptions, verbatim:
#   buildkite_cluster_secret.cluster_id  "The UUID of the cluster this secret belongs to."
#   buildkite_cluster_queue.cluster_id   "The ID of the cluster that this cluster queue belongs to."
# Same attribute name, different identifier: the queue wants the base64 GraphQL
# id, the secret wants the plain uuid. Copying a working cluster_id from the 3.2
# queue pack into this one fails. This pack never hand-writes either: it resolves
# clusters by name through data.buildkite_cluster and reads `.uuid`.
#
# ── ⚠️ TRAP 4: no policy is a cluster-wide grant ─────────────────────────────
# A secret is reachable by agents in its cluster; the access policy is what
# narrows that to specific builds. Buildkite does not document the behaviour of a
# secret with no policy at all, so this pack refuses to create one rather than
# guess — same posture the guide takes on the value-size discrepancy. Declaring
# `policy_rules` is mandatory here, and an empty list fails the plan.
#
# ── ⚠️ TRAP 5: third-party claims are attacker-influenced ────────────────────
# Vendor, verbatim: "First-party claims are ones whose values are generated by
# Buildkite. This makes these claims more secure than third-party claims", whose
# "values are provided by users or third-party tools." So `pipeline_slug` and
# `build_branch` read like identity and are not: a slug is reusable by a deleted-
# and-recreated pipeline, and branch names are created by whoever can push. A
# rule built only from third-party claims is a soft boundary. The check block
# below reports every such rule; require_first_party_claim turns it into a
# per-secret plan failure.
#
# ── ⚠️ TRAP 6: rules are OR'd, so adding a rule always WIDENS access ─────────
# Vendor, verbatim: "If any of the rules of the policy match, access to the
# secret is granted." Claims within one rule are AND'd; rules are OR'd. Appending
# a rule to "also let staging read it" cannot tighten anything, and a permissive
# rule appended to a strict policy silently supersedes it. Reviews should read
# the widest rule, not the first one.
#
# ── ⚠️ TRAP 7: key naming is validated late and the key is immutable ─────────
# Vendor + provider agree: must start with a letter, letters/numbers/underscores
# only, max 255 chars, and must not begin with `buildkite` or `bk` (case-
# insensitive — those prefixes are reserved). The Key cannot be changed after
# creation, so a typo is a create-and-delete, not an edit. The preconditions
# below fail the plan on the operator's machine rather than mid-apply.
#
# ── ⚠️ TRAP 7b: THE MAP LABEL IS NOT THE SECRET KEY ──────────────────────────
# `var.cluster_secrets` is a map keyed by a Terraform LABEL, and every entry
# additionally declares `key`, which is the name the secret is created under in
# Buildkite and the name a pipeline references. They are deliberately separate:
# the label is a Terraform address (it must be stable, it appears in state, and
# renaming it moves the resource), while the key is an immutable Buildkite
# identifier. Writing `key = each.key` — using the label — is the specific bug
# this pack must not have: the operator declares `key = "DEPLOY_KEY"`, gets a
# secret named after their label, and every pipeline reading `DEPLOY_KEY` reads
# nothing. Every reference below reads `each.value.key`; the label is used only
# to identify the declaration in error messages.
#
# Because the key is no longer forced unique by the map's own keys, the
# uniqueness precondition below rejects two entries that declare the same key in
# the same cluster — a collision Buildkite would otherwise resolve by having the
# second apply fight the first.
#
# ── ⚠️ TRAP 8: Terraform cannot verify the value it stored ───────────────────
# Secret values are write-only in the Buildkite API and cannot be read back. No
# drift detection exists on the value: if somebody overwrites the secret in the
# console, Terraform reports no changes forever. value_wo_version is a promise
# about intent, not evidence about state. Value rotation must be audited from the
# upstream secret manager, not from this configuration.
#
# ── SIZE LIMIT ───────────────────────────────────────────────────────────────
# Provider schema says "Must be less than 8KB"; the Buildkite secrets docs say
# "up to a maximum of 32 kilobytes". Unreconciled, so design against 8 KB. This
# pack deliberately does NOT precondition on length: value_wo is ephemeral and is
# not available to expressions, so any such check would have to read the plaintext
# into a non-ephemeral expression — reintroducing exactly the state exposure the
# resource exists to avoid. Enforce size where the secret is minted instead.
#
# ── VERIFICATION STATUS: DRIFT-CHECKED-ONLY ──────────────────────────────────
# Every attribute, type, requiredness and constraint above was read from the live
# provider schema (`tofu providers schema -json`, buildkite/buildkite v1.38.0):
# cluster_id + key required; value/value_wo optional+sensitive; value_wo carries
# "write_only": true; value_wo_version typed string; policy optional; created_at/
# updated_at/id computed. Policy semantics, claim names, first-vs-third-party
# trust and key constraints were read from Buildkite's secrets and access-policy
# documentation. NOT APPLIED: creating a cluster secret writes a credential to
# the principal's real organization, so no resource in this file was executed
# against the tenant.
# =============================================================================

# Declared HERE and not in the shared variables.tf, on purpose: `ephemeral = true`
# is what raises this directory's toolchain floor, so the declaration lives with
# the only pack that needs it. Adopting 3.5 means adopting the floor; deleting
# this file removes both. See the VERSION FLOOR note above.
variable "cluster_secret_values" {
  description = "Secret material for var.cluster_secrets, keyed identically. EPHEMERAL: pack 3.5 passes each value to Buildkite through the resource's write-only `value_wo` argument, so it is never written to a plan file or to state and cannot be recovered by anyone holding state. Supply from an ephemeral resource, an uncommitted -var-file, or TF_VAR_ variables sourced from your secret manager. Note the size ceiling is disputed: the Terraform provider documents 8 KB while Buildkite's own secrets documentation says 32 KB — design to the lower figure."
  type        = map(string)
  ephemeral   = true
  sensitive   = true
  default     = {}
}

# HTH Guide Excerpt: begin manage-cluster-secrets
locals {
  # Claims Buildkite generates itself. A rule anchored on one of these cannot be
  # satisfied by naming a branch or reusing a slug (TRAP 5).
  hth_first_party_claims = ["pipeline_id", "build_source", "cluster_queue_id"]

  # Claims whose values originate with users or third-party tools.
  hth_third_party_claims = [
    "pipeline_slug", "build_branch", "build_creator",
    "build_creator_team", "cluster_queue_key",
  ]

  hth_known_claims = concat(local.hth_first_party_claims, local.hth_third_party_claims)

  # Every cluster that holds a declared secret. Resolved by NAME so the uuid this
  # resource requires is never hand-copied from a queue's GraphQL id (TRAP 3).
  hth_secret_clusters = toset([for s in var.cluster_secrets : s.cluster])

  # Per-secret policy analysis, computed once and reused by the resource
  # preconditions and by the audit checks below.
  hth_secret_policy = {
    for k, s in var.cluster_secrets : k => {
      # Every claim key used anywhere in the policy, for typo detection.
      claims_used = distinct(flatten([for rule in s.policy_rules : keys(rule)]))

      # Rules that name no first-party claim at all. Each is a boundary that a
      # branch push or a recreated pipeline slug can walk through.
      third_party_only_rules = [
        for i, rule in s.policy_rules : i
        if length(setintersection(toset(keys(rule)), toset(local.hth_first_party_claims))) == 0
      ]

      # A rule with no claims would match every build. Terraform's type system
      # permits the empty map, so it is rejected here.
      empty_rules = [for i, rule in s.policy_rules : i if length(keys(rule)) == 0]

      # TRAP 7b: how many declarations target this same (cluster, key) pair.
      # The map label makes the Terraform address unique; nothing makes the
      # Buildkite key unique, and two entries claiming one key in one cluster is
      # two applies overwriting each other's credential.
      key_collisions = [
        for k2, s2 in var.cluster_secrets : k2
        if s2.cluster == s.cluster && s2.key == s.key
      ]
    }
  }
}

data "buildkite_cluster" "secret_scoped" {
  for_each = local.hth_secret_clusters

  name = each.value
}

# Cluster-scoped secrets. The value never enters Terraform state or a plan file:
# it arrives through the ephemeral var.cluster_secret_values map and leaves
# through the write-only value_wo argument.
resource "buildkite_cluster_secret" "managed" {
  # TRAP 1: this map is deliberately NOT sensitive. It carries no secret values —
  # only the cluster, version marker and policy — so it is legal to iterate.
  for_each = var.cluster_secrets

  cluster_id = data.buildkite_cluster.secret_scoped[each.value.cluster].uuid

  # TRAP 7b: the DECLARED key, never the map label. The label is a Terraform
  # address; this is the name Buildkite creates the secret under and the name a
  # pipeline references. It is immutable — changing it is a create-plus-delete.
  key = each.value.key

  description = each.value.description

  # TRAP 1 + the reason this pack exists. Indexed inside the resource body, never
  # in for_each. Ephemeral input -> write-only argument: no plan file, no state.
  value_wo = var.cluster_secret_values[each.key]

  # TRAP 2: string, and the ONLY signal Terraform has that the value changed.
  value_wo_version = each.value.value_wo_version

  # TRAP 6: a YAML list of rules, OR'd. Built from a typed structure so a
  # mistyped claim fails the plan instead of becoming an inert line of YAML.
  policy = yamlencode(each.value.policy_rules)

  lifecycle {
    # TRAP 4: refuse to create a secret with no policy.
    precondition {
      condition     = length(each.value.policy_rules) > 0
      error_message = format("Secret '%s' (Buildkite key '%s') declares no policy_rules. A cluster secret with no access policy is not a documented state — Buildkite does not specify whether it is reachable by every build in cluster '%s'. Declare the pipelines that may read it.", each.key, each.value.key, each.value.cluster)
    }

    # TRAP 6, degenerate case: a claimless rule constrains nothing, and because
    # rules are OR'd it makes every other rule in the policy irrelevant.
    precondition {
      condition     = length(local.hth_secret_policy[each.key].empty_rules) == 0
      error_message = format("Secret '%s' (Buildkite key '%s') has policy rule(s) at index %s with no claims. Rules are OR'd, so a claimless rule matches every build and supersedes every other rule in the policy.", each.key, each.value.key, join(", ", [for i in local.hth_secret_policy[each.key].empty_rules : tostring(i)]))
    }

    # A misspelled claim is the worst failure mode available here: it reads like
    # a restriction and enforces nothing.
    precondition {
      condition     = length(setsubtract(toset(local.hth_secret_policy[each.key].claims_used), toset(local.hth_known_claims))) == 0
      error_message = format("Secret '%s' (Buildkite key '%s') uses unrecognised policy claim(s): %s. Buildkite implements exactly these: first-party %s; third-party %s.", each.key, each.value.key, join(", ", tolist(setsubtract(toset(local.hth_secret_policy[each.key].claims_used), toset(local.hth_known_claims)))), join(", ", local.hth_first_party_claims), join(", ", local.hth_third_party_claims))
    }

    # TRAP 5, enforced per secret when the operator opts in.
    precondition {
      condition     = !var.require_first_party_claim || length(local.hth_secret_policy[each.key].third_party_only_rules) == 0
      error_message = format("Secret '%s' (Buildkite key '%s') has policy rule(s) at index %s built only from third-party claims, whose values are supplied by users or third-party tools. Anchor each rule on pipeline_id, build_source or cluster_queue_id, or set require_first_party_claim = false to accept the softer boundary deliberately.", each.key, each.value.key, join(", ", [for i in local.hth_secret_policy[each.key].third_party_only_rules : tostring(i)]))
    }

    # TRAP 7 + 7b: the key is immutable, so a typo costs a create-and-delete
    # cycle — and the string validated here is the DECLARED key that Buildkite
    # will actually receive, not the map label. Validating the label would pass a
    # well-formed address while creating a malformed credential.
    precondition {
      condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,254}$", each.value.key))
      error_message = format("Secret '%s' declares an invalid Buildkite key '%s'. Keys must start with a letter, contain only letters, numbers and underscores, and be at most 255 characters. The key cannot be changed after creation.", each.key, each.value.key)
    }

    precondition {
      condition     = !startswith(lower(each.value.key), "buildkite") && !startswith(lower(each.value.key), "bk")
      error_message = format("Secret '%s' declares the Buildkite key '%s', which uses a reserved prefix. Keys must not begin with 'buildkite' or 'bk' in any casing.", each.key, each.value.key)
    }

    # TRAP 7b: the map label guarantees a unique Terraform address; nothing
    # guarantees a unique Buildkite key. Two declarations naming one key in one
    # cluster are two resources writing the same credential.
    precondition {
      condition     = length(local.hth_secret_policy[each.key].key_collisions) == 1
      error_message = format("Buildkite key '%s' in cluster '%s' is declared by %d entries of var.cluster_secrets: %s. The map label is a Terraform address and does not make the key unique — these declarations would overwrite one another's value and policy. Give each secret its own key.", each.value.key, each.value.cluster, length(local.hth_secret_policy[each.key].key_collisions), join(", ", local.hth_secret_policy[each.key].key_collisions))
    }

    # TRAP 2, the other half: the provider requires a non-empty version marker.
    precondition {
      condition     = trimspace(each.value.value_wo_version) != ""
      error_message = format("Secret '%s' (Buildkite key '%s') has an empty value_wo_version. It is required whenever value_wo is set, and it is the only change Terraform can detect when the secret value rotates.", each.key, each.value.key)
    }
  }
}
# HTH Guide Excerpt: end manage-cluster-secrets

# HTH Guide Excerpt: begin audit-secret-policies
# The preconditions above govern secrets this configuration creates. These checks
# report on the shape of the estate every plan and apply without blocking an
# unrelated deploy — the standing question at review time is not "did it apply"
# but "how wide is the widest rule".

# TRAP 5 as a reporting control, so the finding is visible even when
# require_first_party_claim is deliberately false.
check "secret_policies_anchored_on_first_party_claims" {
  assert {
    condition = length([
      for k, p in local.hth_secret_policy : k if length(p.third_party_only_rules) > 0
    ]) == 0
    error_message = format(
      "%d secret(s) have at least one policy rule built only from third-party claims (values supplied by users or third-party tools, per Buildkite): %s. A pipeline_slug is reusable by a recreated pipeline and a build_branch is created by anyone who can push, so these rules do not bind the way they read.",
      length([for k, p in local.hth_secret_policy : k if length(p.third_party_only_rules) > 0]),
      jsonencode({ for k, p in local.hth_secret_policy : k => p.third_party_only_rules if length(p.third_party_only_rules) > 0 }),
    )
  }
}

# A secret every pipeline can read is the state control 3.2's cluster boundary
# was built to prevent — it re-broadens the blast radius inside the cluster.
check "secret_policies_are_scoped_to_pipelines" {
  assert {
    condition = length([
      for k, s in var.cluster_secrets : k
      if !contains(local.hth_secret_policy[k].claims_used, "pipeline_id")
      && !contains(local.hth_secret_policy[k].claims_used, "pipeline_slug")
    ]) == 0
    error_message = format(
      "%d secret(s) carry a policy that never names a pipeline: %s. Every build in the cluster that satisfies the remaining claims can read them. Prefer pipeline_id — it survives a pipeline being deleted and recreated under the same slug.",
      length([for k, s in var.cluster_secrets : k if !contains(local.hth_secret_policy[k].claims_used, "pipeline_id") && !contains(local.hth_secret_policy[k].claims_used, "pipeline_slug")]),
      jsonencode([for k, s in var.cluster_secrets : k if !contains(local.hth_secret_policy[k].claims_used, "pipeline_id") && !contains(local.hth_secret_policy[k].claims_used, "pipeline_slug")]),
    )
  }
}

# Cross-check against control 3.5 Step 4: production secrets belong in the
# production cluster only. Any secret whose declared cluster is not on the
# approved list for its sensitivity is a placement finding.
check "secrets_placed_in_declared_clusters" {
  assert {
    condition = length([
      for k, s in var.cluster_secrets : k
      if length(var.production_secret_clusters) > 0
      && s.production
      && !contains(var.production_secret_clusters, s.cluster)
    ]) == 0
    error_message = format(
      "%d secret(s) marked production are stored in a cluster not listed in production_secret_clusters: %s. A production credential in a development cluster is reachable by every agent registered to that cluster, which undoes the isolation established in control 3.2.",
      length([for k, s in var.cluster_secrets : k if length(var.production_secret_clusters) > 0 && s.production && !contains(var.production_secret_clusters, s.cluster)]),
      jsonencode([for k, s in var.cluster_secrets : k if length(var.production_secret_clusters) > 0 && s.production && !contains(var.production_secret_clusters, s.cluster)]),
    )
  }
}

# Metadata only. The value is write-only in the Buildkite API and unreadable by
# design, so there is deliberately nothing here that could carry it.
output "cluster_secrets_managed" {
  description = "Declared cluster secrets and the shape of their access policies, keyed by the var.cluster_secrets DECLARATION LABEL. `key` is the separate, immutable Buildkite key the secret was created under and the name a pipeline must reference (TRAP 7b) — compare the two when a pipeline reports an empty secret. Contains no secret material — values are write-only and cannot be read back from Buildkite (TRAP 8: this means Terraform can never detect a console overwrite of a value)."
  value = {
    for k, s in buildkite_cluster_secret.managed : k => {
      id                     = s.id
      key                    = s.key
      cluster                = var.cluster_secrets[k].cluster
      cluster_uuid           = s.cluster_id
      value_wo_version       = s.value_wo_version
      created_at             = s.created_at
      updated_at             = s.updated_at
      policy_rule_count      = length(var.cluster_secrets[k].policy_rules)
      policy_claims_used     = local.hth_secret_policy[k].claims_used
      third_party_only_rules = local.hth_secret_policy[k].third_party_only_rules
    }
  }
}
# HTH Guide Excerpt: end audit-secret-policies
