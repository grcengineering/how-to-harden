# =============================================================================
# HTH Buildkite Control 2.7: Govern Cross-Pipeline Access with Buildkite Rules
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-4 (Information Flow Enforcement) | NIST AC-3 (Access Enforcement)
# Source: https://howtoharden.com/guides/buildkite/#27-govern-cross-pipeline-access-with-buildkite-rules
#
# Every other control in section 3 builds isolation: clusters separate agents,
# cluster-scoped tokens separate registration, private pipelines separate
# visibility. A Buildkite Rule is the one object that punches through all three
# at once. Buildkite's own documentation says a trigger rule "overrides the usual
# trigger step permissions checks on users and teams", and that both rule types
# work when "both pipelines are in the same or different clusters" and when "one
# pipeline is public and another is private". A rule is therefore not a policy —
# it is a deliberate, standing hole in the boundary the rest of the guide built,
# and it belongs in version control where somebody reviews it.
#
# GRANT-ONLY, NEVER DENY. Live GraphQL introspection of this organization's
# schema returns RuleEffect with exactly one member: ALLOW. RuleAction has two:
# TRIGGER_BUILD and ARTIFACTS_READ. RuleSourceType has one: PIPELINE. There is no
# deny rule and no way to write one. Deny is the platform default; a rule only
# ever subtracts from it. Reviewing a rule means asking "should this hole exist",
# never "is this rule restrictive enough".
#
# TRAP 1 — `effect` is COMPUTED, and so are `action`, `source_type`,
# `source_uuid`, `target_type`, `target_uuid`. The provider accepts exactly three
# inputs: `type`, `value`, `description`. Writing `effect = "allow"` is a plan
# error, not a stricter rule. Everything expressive lives inside the `value` JSON
# document.
#
# TRAP 2 — OMITTING `conditions` IS AN UNCONDITIONAL GRANT. Buildkite: "If no
# conditions are specified, triggering is allowed in all cases between the source
# and target pipelines." A three-line rule with no conditions lets any build, on
# any branch, from any actor in the source pipeline reach the target forever.
# This pack refuses to create a conditionless rule unless its key is named in
# var.unconditional_rule_exceptions, so the exception is written down.
#
# TRAP 3 — DIRECTION INVERTS MEANING AND STILL APPLIES CLEANLY. For
# pipeline.trigger_build.pipeline, `source_pipeline` is the pipeline that gets to
# fire the trigger. For pipeline.artifacts_read.pipeline, `source_pipeline` is
# the pipeline that gets to READ the other's artifacts. Swap them and Terraform
# reports success while the hole faces the wrong way. The postcondition below
# re-reads the computed action Buildkite actually assigned and compares it to the
# action the declared type implies.
#
# TRAP 4 — SLUGS ARE MUTABLE, UUIDs ARE NOT. `source_pipeline`/`target_pipeline`
# accept either a pipeline UUID or a pipeline slug. The provider resolves the
# reference at PLAN time — a name that matches nothing fails loudly with
# "Unable to resolve pipeline slug" (verified live against a tenant with no
# pipelines), so typos are not the risk. The risk is the slug that DOES resolve:
# slugs are reusable, so deleting a pipeline and recreating one under the same
# slug silently re-points the rule at a new pipeline that inherits the old one's
# trust. Prefer UUIDs. When a UUID is supplied, the postcondition below asserts
# Buildkite resolved to that exact pipeline.
#
# TRAP 5 — HCL EATS `${`. Conditions are Buildkite conditionals, single-quoted
# ('main'), which is safe inside a double-quoted HCL string. But any literal `${`
# in a condition must be escaped as `$${` or Terraform will try to interpolate it.
#
# Verification: provider schema introspected live (buildkite/buildkite v1.38.0 —
# `type` and `value` required, six computed attributes); RuleEffect/RuleAction/
# RuleSourceType enums introspected live from the tenant GraphQL schema; REST
# GET /v2/organizations/{org}/rules returned HTTP 200 on the live tenant. No rule
# was created — this session was read-only, so the create/update round-trip is
# schema- and vendor-doc-verified, not tenant-executed.
# =============================================================================

# HTH Guide Excerpt: begin grant-cross-pipeline-access
locals {
  # The action Buildkite assigns for each rule type. Introspected from the live
  # RuleAction enum: TRIGGER_BUILD, ARTIFACTS_READ. Used to prove the rule that
  # was created does what the declared type claims.
  hth_rule_expected_action = {
    "pipeline.trigger_build.pipeline"  = "TRIGGER_BUILD"
    "pipeline.artifacts_read.pipeline" = "ARTIFACTS_READ"
  }

  hth_uuid_pattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
}

# One resource per approved cross-boundary grant. Each entry is a documented
# exception to cluster and visibility isolation, reviewed as code.
resource "buildkite_organization_rule" "cross_pipeline" {
  for_each = var.cross_pipeline_rules

  type = each.value.type

  description = coalesce(
    each.value.description,
    format("HTH 2.7 - %s: %s -> %s", each.value.type, each.value.source_pipeline, each.value.target_pipeline),
  )

  # `conditions` is omitted from the document entirely when empty, because
  # Buildkite treats an absent conditions array and an empty one the same way:
  # unconditional. The precondition below is what actually stops that happening.
  value = jsonencode(merge(
    {
      source_pipeline = each.value.source_pipeline
      target_pipeline = each.value.target_pipeline
    },
    length(each.value.conditions) > 0 ? { conditions = each.value.conditions } : {},
  ))

  lifecycle {
    # TRAP 2. A rule with no conditions is a standing, unscoped grant. Creating
    # one has to be a named decision, not a default.
    precondition {
      condition = length(each.value.conditions) > 0 || contains(var.unconditional_rule_exceptions, each.key)
      error_message = format(
        "Rule '%s' declares no conditions, which grants %s from '%s' to '%s' for every build on every branch, permanently. Add conditions (for example \"source.build.branch == 'main'\") or add '%s' to var.unconditional_rule_exceptions to record the decision.",
        each.key,
        each.value.type,
        each.value.source_pipeline,
        each.value.target_pipeline,
        each.key,
      )
    }

    # TRAP 3. Re-read the action Buildkite assigned and compare it to the action
    # the declared type implies. Catches a type/direction copy-paste that would
    # otherwise apply successfully with the hole facing the wrong way.
    postcondition {
      condition = upper(self.action) == local.hth_rule_expected_action[each.value.type]
      error_message = format(
        "Rule '%s' declared type '%s' (expected action %s) but Buildkite created action '%s'. Re-read the source/target direction before keeping this rule.",
        each.key,
        each.value.type,
        local.hth_rule_expected_action[each.value.type],
        self.action,
      )
    }

    # TRAP 4. When the operator supplied UUIDs, prove Buildkite resolved to those
    # exact pipelines. Slug-declared rules skip this check by design - which is
    # itself the argument for declaring UUIDs.
    postcondition {
      condition = (
        !can(regex(local.hth_uuid_pattern, each.value.source_pipeline))
        || lower(self.source_uuid) == lower(each.value.source_pipeline)
      )
      error_message = format(
        "Rule '%s' declared source pipeline UUID '%s' but resolved to '%s'.",
        each.key, each.value.source_pipeline, self.source_uuid,
      )
    }

    postcondition {
      condition = (
        !can(regex(local.hth_uuid_pattern, each.value.target_pipeline))
        || lower(self.target_uuid) == lower(each.value.target_pipeline)
      )
      error_message = format(
        "Rule '%s' declared target pipeline UUID '%s' but resolved to '%s'.",
        each.key, each.value.target_pipeline, self.target_uuid,
      )
    }
  }
}

output "cross_pipeline_rule_grants" {
  description = "Every standing cross-pipeline grant, as Buildkite resolved it. Review this list, not the input variables - these are the UUIDs the platform actually enforces against."
  value = {
    for k, r in buildkite_organization_rule.cross_pipeline : k => {
      uuid        = r.uuid
      effect      = r.effect
      action      = r.action
      source_uuid = r.source_uuid
      target_uuid = r.target_uuid
      conditional = length(var.cross_pipeline_rules[k].conditions) > 0
    }
  }
}
# HTH Guide Excerpt: end grant-cross-pipeline-access

# HTH Guide Excerpt: begin audit-console-created-rules
# Rules can also be created in the Buildkite console, and the provider offers no
# resource or data source that enumerates every rule in the organization - only a
# lookup by known UUID. So the Terraform-side audit is: pin the rules you
# reviewed and prove they still point where you approved. Use the REST endpoint
# GET /v2/organizations/{org}/rules (verified HTTP 200) to discover UUIDs that
# appeared out of band, then pin them here or delete them.
data "buildkite_organization_rule" "reviewed" {
  for_each = var.reviewed_rules

  uuid = each.value.uuid
}

# A `check` block is continuous validation: it reports on every plan and apply
# and does NOT block the apply. It is the right shape here because re-pointed
# rules are a review finding, not a reason to fail an unrelated deploy. If a
# pinned rule is deleted in the console the data source read errors instead,
# which is the loud failure you want for a vanished approval record.
check "reviewed_rules_still_point_where_approved" {
  assert {
    condition = alltrue([
      for k, r in data.buildkite_organization_rule.reviewed :
      lower(r.source_uuid) == lower(var.reviewed_rules[k].source_uuid)
      && lower(r.target_uuid) == lower(var.reviewed_rules[k].target_uuid)
    ])
    error_message = format(
      "A reviewed Buildkite rule now grants access between different pipelines than the ones approved. Approved: %s. Live: %s.",
      jsonencode({ for k, v in var.reviewed_rules : k => "${v.source_uuid} -> ${v.target_uuid}" }),
      jsonencode({ for k, r in data.buildkite_organization_rule.reviewed : k => "${r.source_uuid} -> ${r.target_uuid}" }),
    )
  }
}

output "reviewed_rule_audit" {
  description = "Live state of every out-of-band rule pinned for review. `effect` is always ALLOW - the enum has no other value - so the security question is whether the grant should exist at all."
  value = {
    for k, r in data.buildkite_organization_rule.reviewed : k => {
      effect      = r.effect
      action      = r.action
      source_uuid = r.source_uuid
      target_uuid = r.target_uuid
      description = r.description
    }
  }
}
# HTH Guide Excerpt: end audit-console-created-rules
