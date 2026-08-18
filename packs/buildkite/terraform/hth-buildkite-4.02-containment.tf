# =============================================================================
# HTH Buildkite Control 4.2: Contain a Compromised Build Fleet
#   — QUEUE-DISPATCH half (the only half Terraform can reach)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 17.4 | NIST 800-53 IR-4
# Source: https://howtoharden.com/guides/buildkite/#42-contain-a-compromised-build-fleet
#
# PAIRS WITH: packs/buildkite/cli/hth-buildkite-4.02-agent-containment.sh
# This file can pause a QUEUE. It cannot touch an AGENT: the provider (v1.38.0)
# ships no `buildkite_agent` resource and no agent data source, so every agent
# verb — pause, resume, stop, forced stop — is CLI/GraphQL only. Pausing dispatch
# stops NEW jobs being handed out; the job already executing on a compromised
# agent keeps running. Applying only this file is a half-contained fleet.
#
# -----------------------------------------------------------------------------
# ⚠️ THE TRAP THIS PACK EXISTS TO NOT SET: dispatch_paused IS optional + COMPUTED
# -----------------------------------------------------------------------------
# `tofu providers schema -json` for buildkite/buildkite v1.38.0:
#     dispatch_paused: type=bool required=false optional=true computed=true
#
# Optional+computed means an UNSET attribute adopts whatever the server says, and
# a SET attribute is reconciled to your value on every apply. So a queue pack that
# writes `dispatch_paused = false` — including a pack that writes it by accident,
# via a variable whose default is `false` — will RE-ENABLE DISPATCH on the next
# apply. During an incident that is not drift correction; it is a scheduled job
# racing the responder who just paused the queue in the console, and handing work
# back to the fleet they are trying to contain. A routine `terraform apply` from
# CI is enough to fire it.
#
# This pack therefore NEVER emits a bare `false`. `local.hth_containment_dispatch`
# resolves to `null` — genuinely unset — in every case except two deliberate ones:
#   * break_glass_pause_all = true, or an entry's break_glass_pause = true  -> true
#   * an entry's break_glass_pause = false AND its key is listed in
#     var.acknowledged_resume_queues                                       -> false
# An unacknowledged `false` is COERCED TO null (fail-safe: containment survives)
# and reported by the check block below, so the operator learns their resume did
# not take effect instead of discovering it in the audit log.
#
# COROLLARY FOR THE REST OF THIS DIRECTORY: pack 3.3's var.agent_queues carried
# `paused = optional(bool, false)` and passed it straight to dispatch_paused, so
# every 3.3-managed queue was hard-set unpaused on every apply. That default is
# now `null`. If you re-add a `false` default anywhere, you have re-armed this.
#
# -----------------------------------------------------------------------------
# TRAP 2 — cluster_id IS THE GRAPHQL ID, NOT THE UUID
# -----------------------------------------------------------------------------
# buildkite_cluster_queue.cluster_id takes the opaque base64 GraphQL id (provider
# docs: "The ID of the cluster"), while buildkite_cluster_maintainer.cluster_uuid
# in pack 3.7 takes the plain uuid. Both are resolved here by name through
# data.buildkite_cluster so the two cannot be transposed by hand.
#
# TRAP 3 — THIS RESOURCE CREATES. IMPORT FIRST OR YOU FIGHT YOURSELF.
# A queue you already have is not adopted; Terraform tries to create a second one
# with the same key. Import before the first apply. The import id is a PAIR,
# "<queue GraphQL id>,<cluster uuid>" (provider docs, resources/cluster_queue.md):
#
#   import {
#     to = buildkite_cluster_queue.containment["prod-default"]
#     id = "Q2x1c3RlclF1ZXVlLS0t...,35498aaf-ad05-4fa5-9a07-91bf6cacd2bd"
#   }
#
# Find the queue id with the query in the CLI pack's `queues` verb, or the one the
# provider documents: organization(slug:){ cluster(id: CLUSTER_UUID){ queues } }.
#
# TRAP 4 — TERRAFORM CANNOT ENUMERATE PAUSED QUEUES IT DOES NOT MANAGE.
# There is no buildkite_cluster_queue DATA SOURCE (16 data sources exist; this is
# not one). Live dispatch state is readable only for queues under management here,
# via each resource's own computed attribute after refresh. A queue somebody
# paused in the console and forgot is invisible to this file — that sweep lives in
# the CLI pack (`hth-buildkite-4.02-agent-containment.sh status`).
#
# AUTHORING STATUS: DRIFT-CHECKED-ONLY.
# Every attribute, type and optional/computed flag above was read from
# `tofu providers schema -json` against buildkite/buildkite v1.38.0, and the
# import-id format from the provider's own docs/resources/cluster_queue.md.
# `tofu validate` passes with this file and packs 3.1, 3.2, 3.3 and 3.7 present in
# one directory. No apply and no plan against the tenant was executed: pausing a
# queue on the principal's live organization is an availability action, and
# creating one is a resource this session must not make. The live queue inventory
# the checks below reason about WAS read, read-only, over GraphQL — five queues,
# all dispatchPaused=false — via the CLI pack's `queues` verb.
# =============================================================================

# HTH Guide Excerpt: begin contain-queue-dispatch
locals {
  # Clusters holding a queue under containment management, resolved by name so the
  # GraphQL id (TRAP 2) is never typed by hand.
  hth_containment_clusters = toset([for q in var.containment_queues : q.cluster])

  # Effective dispatch_paused per queue. `null` is the important value: it leaves
  # the attribute unset, so Terraform adopts server state and can never revert an
  # out-of-band incident pause (see the header).
  hth_containment_dispatch = {
    for k, q in var.containment_queues : k => (
      var.break_glass_pause_all ? true :
      q.break_glass_pause == true ? true :
      (q.break_glass_pause == false && contains(var.acknowledged_resume_queues, k)) ? false :
      null
    )
  }

  # Entries asking to resume without the acknowledgement. Coerced to null above,
  # reported below — a silently-ignored resume is worse than a refused one.
  hth_containment_unacknowledged_resumes = [
    for k, q in var.containment_queues : k
    if q.break_glass_pause == false && !contains(var.acknowledged_resume_queues, k)
  ]
}

data "buildkite_cluster" "containment" {
  for_each = local.hth_containment_clusters

  name = each.value
}

# Queues whose dispatch state is part of the incident-response surface. Pausing
# dispatch stops new jobs being handed out WITHOUT deleting the queue, so restore
# is a resume rather than a rebuild of queue configuration.
resource "buildkite_cluster_queue" "containment" {
  for_each = var.containment_queues

  cluster_id  = data.buildkite_cluster.containment[each.value.cluster].id
  key         = each.value.key
  description = each.value.description

  # null in the ordinary case. Never a bare `false`.
  dispatch_paused = local.hth_containment_dispatch[each.key]

  lifecycle {
    # A fleet-wide break-glass pause and a per-queue resume are contradictory
    # instructions. Mid-incident that is a typo, not an intent — fail the plan
    # rather than let the reader guess which one won.
    precondition {
      condition = !(var.break_glass_pause_all && each.value.break_glass_pause == false)
      error_message = format(
        "Queue '%s' sets break_glass_pause = false while var.break_glass_pause_all is true. Resolve the contradiction: drop the entry's false, or clear the fleet-wide break glass.",
        each.key,
      )
    }
  }
}

output "containment_queue_targets" {
  description = "Queues under containment management and the dispatch_paused value Terraform will send. `null` means the attribute is left unset, so an out-of-band pause survives the next apply."
  value = {
    for k, q in var.containment_queues : k => {
      cluster         = q.cluster
      key             = q.key
      cluster_id      = data.buildkite_cluster.containment[q.cluster].id
      cluster_uuid    = data.buildkite_cluster.containment[q.cluster].uuid
      dispatch_paused = local.hth_containment_dispatch[k]
      managed         = local.hth_containment_dispatch[k] != null
    }
  }
}
# HTH Guide Excerpt: end contain-queue-dispatch

# HTH Guide Excerpt: begin audit-queue-dispatch-state
# The write half above governs intent. This half reads what is actually true.
# There is no cluster_queue data source (TRAP 4), so live state is only legible
# through each managed resource's own computed dispatch_paused after refresh —
# which is exactly enough to answer the two questions that matter after an
# incident: is anything still paused, and did anyone ask for a resume that this
# configuration silently declined to make.
locals {
  hth_containment_paused_now = [
    for k, q in buildkite_cluster_queue.containment : k if q.dispatch_paused
  ]
}

# Continuous validation: reports on every plan and apply, does not block. A queue
# left paused after the incident closed is a silent outage — the builds simply
# never start — so surface it every run instead of waiting for someone to ask why
# the deploy pipeline has been quiet.
check "no_queue_left_paused" {
  assert {
    condition = length(local.hth_containment_paused_now) == 0
    error_message = format(
      "%d cluster queue(s) currently have dispatch PAUSED and are handing out no jobs: %s. If the incident is closed, resume them deliberately (set break_glass_pause = false AND list the key in var.acknowledged_resume_queues, or resume via the 4.2 CLI pack). If it is open, this is the expected state.",
      length(local.hth_containment_paused_now),
      jsonencode(local.hth_containment_paused_now),
    )
  }
}

# A resume that did not happen must never look like a resume that did.
check "resume_requests_are_acknowledged" {
  assert {
    condition = length(local.hth_containment_unacknowledged_resumes) == 0
    error_message = format(
      "%d queue(s) request break_glass_pause = false without acknowledgement and were COERCED TO UNSET, so dispatch was NOT resumed: %s. Add each key to var.acknowledged_resume_queues to make the resume take effect. The coercion is deliberate: an unreviewed `false` in a queue pack is how a routine apply un-contains a fleet.",
      length(local.hth_containment_unacknowledged_resumes),
      jsonencode(local.hth_containment_unacknowledged_resumes),
    )
  }
}

output "containment_dispatch_state" {
  description = "Live dispatch state for every managed containment queue, plus resume requests this configuration declined to act on. Terraform cannot see queues it does not manage — use the 4.2 CLI pack's `status` verb for the unmanaged sweep."
  value = {
    live = {
      for k, q in buildkite_cluster_queue.containment : k => {
        queue_id        = q.id
        queue_uuid      = q.uuid
        cluster_uuid    = q.cluster_uuid
        dispatch_paused = q.dispatch_paused
      }
    }
    paused_now             = local.hth_containment_paused_now
    unacknowledged_resumes = local.hth_containment_unacknowledged_resumes
  }
}
# HTH Guide Excerpt: end audit-queue-dispatch-state
