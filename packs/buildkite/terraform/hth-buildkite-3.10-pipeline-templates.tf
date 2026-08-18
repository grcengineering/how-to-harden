# =============================================================================
# HTH Buildkite Control 3.10: Standardize Pipeline Steps with Templates
# Profile Level: L3 (Run)
# Frameworks: CIS Controls 4.1 | NIST 800-53 CM-2 (Baseline Configuration),
#             CM-6 (Configuration Settings)
# Source: https://howtoharden.com/guides/buildkite/#310-standardize-pipeline-steps-with-templates
#
# DRIFT-CHECKED-ONLY (authored from verified schema; tenant plan cannot exercise
# this). Pipeline templates are an Enterprise feature and Buildkite's banner says
# so explicitly. The `grcengineering` tenant reads as non-Enterprise, so nothing
# here was applied or planned against a live organization. Every attribute comes
# from `tofu providers schema -json` for buildkite/buildkite v1.38.0:
# buildkite_pipeline_template {name R, configuration R, description O,
# available O+C, id C, uuid C}; its data source {name O+C, id O+C, configuration
# C, description C, available C, uuid C}; and buildkite_pipeline
# .pipeline_template_id (string, optional, "The GraphQL ID of the pipeline
# template applied to this pipeline"). No handle here was inferred from prose.
#
# WHY A TEMPLATE IS A CONTROL AND A CONVENTION IS NOT. A mandated scan step that
# lives in each pipeline's own step configuration is enforced by whoever last
# edited that pipeline. Assigning a template makes the pipeline's step
# configuration read-only, so the step stops being something a pipeline editor
# can quietly delete. That value survives only while the template's own contents
# stay governed — which is why every check below is aimed at the template, not at
# the assignment.
#
# TRAP 1 - `available` IS OPTIONAL **AND COMPUTED**. Omit it and Terraform adopts
# whatever the server holds, so a console operator turning on "available to non
# admin users" never shows as drift. `available` decides whether a non-admin may
# attach this template to a pipeline of their own; a permissive template marked
# available lets a pipeline editor reach the same outcome as deleting a step
# without editing one. This pack always sets it explicitly, and the audit region
# asserts it on templates it does not own.
#
# TRAP 2 - `pipeline_template_id` TAKES THE GRAPHQL ID, NOT THE UUID. This is the
# mirror image of pack 3.7's trap: buildkite_cluster_maintainer wants the plain
# `uuid`, this wants the base64 `id`. Both resources expose both handles, so the
# wrong one is a plausible mistake that fails at apply. Every assignment below
# reads `.id`.
#
# TRAP 3 - `pipeline_template_id` IS PLAIN `optional`, NOT `optional+computed`.
# Every other soft attribute on buildkite_pipeline (`steps`, `visibility`) is
# optional+computed, so omitting them means "adopt server state". This one is not
# computed, so omitting it asserts null and Terraform DETACHES a template that
# was assigned in the console. Consequence across this corpus: pack 2.2's
# `buildkite_pipeline.pipelines` sets no pipeline_template_id, so any pipeline it
# manages has its template stripped on the next apply. A pipeline belongs to
# exactly one resource address — that is why templated pipelines are declared in
# var.templated_pipelines rather than var.pipelines, and why the check
# `pipeline_not_managed_by_two_resources` fails the run when a name is in both.
#
# TRAP 4 - A TEMPLATE THAT ONLY RUNS `buildkite-agent pipeline upload` MOVES THE
# CONTROL BOUNDARY, IT DOES NOT ENFORCE ONE. The uploaded steps come from a file
# in the repository, which the same people change through a pull request, so
# enforcement shifts from Buildkite's pipeline settings to that repository's
# branch protection and review rules. That can be a deliberate design, but it
# does not block the attack this control names — silent removal by a pipeline
# editor — unless the mandated step lives in the template itself. The command is
# spelled identically on buildkite-agent v3 and v4, so this trap is agent-version
# independent. Delegating templates must be named in
# var.templates_allowed_to_delegate_upload, which is the record of that decision.
#
# TRAP 5 - THE ORG-LEVEL "REQUIRE TEMPLATES" STRICTNESS HAS NO TERRAFORM
# RESOURCE. Terraform defines templates and assigns them; it cannot make
# templates mandatory organization-wide. Provider v1.38.0 exposes no such
# resource and no documented mutation covers it — the setting is ClickOps only.
# No HCL is fabricated for it here. Until it is set in the console, a pipeline
# created outside this configuration is created with no template at all, and
# nothing in Terraform will say so.
#
# TRAP 6 - TERRAFORM CANNOT ENUMERATE TEMPLATES OR READ A PIPELINE'S TEMPLATE.
# There is no plural `buildkite_pipeline_templates` data source, and the
# `buildkite_pipeline` DATA SOURCE exposes no pipeline_template_id at all
# (verified attribute set: clone_mirror_url, cluster_id, cluster_name,
# default_branch, description, id, name, repository, slug, uuid, visibility,
# webhook_url). So "which pipelines have no template?" is not answerable from
# Terraform; it needs the GraphQL/REST API. The audit region does what is
# possible: it re-reads templates BY NAME, including console-authored ones this
# configuration does not own, and asserts their contents and their `available`
# flag.
#
# TRAP 7 - PROFILE LEVEL IS NOT AN ON/OFF SWITCH AND MUST NEVER BE A DESTROY
# TRIGGER. An earlier revision gated both resources below on
# `local.hth_templates_active = var.profile_level >= 3`. var.profile_level
# defaults to 1 and the directory README's quick start ran a bare
# `terraform apply`, so the second apply that forgot `-var="profile_level=3"`
# emptied both for_each maps and Terraform DESTROYED every template and every
# pipeline this pack had created - build history and webhook URL gone with them.
# The `check` block at the foot of the first region was named as the mitigation
# and cannot be one: Terraform `check` blocks emit WARNINGS ONLY. They never fail
# a plan and never halt an apply, and under `terraform apply -auto-approve` the
# warning scrolls past a completed destroy. The gate is removed. DECLARATION is
# the switch - an empty var.pipeline_templates / var.templated_pipelines is the
# "off" state and it is the only one. profile_level now only records which level
# this configuration operates at, and the check that says so says out loud that
# it cannot enforce it.
# =============================================================================

# HTH Guide Excerpt: begin standardize-pipeline-steps-with-templates
locals {
  # TRAP 4. Templates that hand step definition back to the repository without an
  # explicit acceptance on file.
  hth_delegating_templates = [
    for name, t in var.pipeline_templates : name
    if length(regexall("buildkite-agent\\s+pipeline\\s+upload", t.configuration)) > 0
    && !contains(var.templates_allowed_to_delegate_upload, name)
  ]

  # Every (template, mandated pattern) pair the template's configuration fails.
  # A template is only a control while it still contains the step.
  hth_templates_missing_required_steps = flatten([
    for name, t in var.pipeline_templates : [
      for pattern in var.required_step_patterns : {
        template = name
        pattern  = pattern
      } if length(regexall(pattern, t.configuration)) == 0
    ]
  ])
}

# The step sequence every pipeline of this class must run. THIS resource is the
# control; the assignment below only points a pipeline at it.
resource "buildkite_pipeline_template" "governed" {
  # TRAP 7. No profile-level gate. The declaration map is the switch; an empty
  # var.pipeline_templates is the off state.
  for_each = var.pipeline_templates

  name          = each.key
  configuration = each.value.configuration
  description   = each.value.description

  # TRAP 1. Always explicit — omitting this adopts server state.
  available = each.value.available

  lifecycle {
    # No prevent_destroy here, deliberately. A template's entire content lives in
    # this configuration, so a destroyed template is recreatable byte-for-byte
    # from `configuration`. A destroyed PIPELINE is not - see the guard on
    # buildkite_pipeline.templated below. Removing a template that a declared
    # pipeline still names is refused anyway, by that pipeline's first
    # precondition.
    precondition {
      condition     = trimspace(each.value.configuration) != ""
      error_message = format("Pipeline template '%s' has an empty configuration. Assigning it would make every adopting pipeline's step configuration read-only AND empty, which deletes their steps instead of standardizing them.", each.key)
    }

    # The configuration is a whole step document, not a fragment: it carries its
    # own `steps:` key. A fragment produces a template that fails at build time on
    # every pipeline assigned to it, all at once.
    precondition {
      condition     = length(regexall("(?m)^steps:", each.value.configuration)) > 0
      error_message = format("Pipeline template '%s' has no top-level `steps:` key. buildkite_pipeline_template.configuration is the complete YAML step configuration, not a list fragment.", each.key)
    }
  }
}

locals {
  # TRAP 2, resolved once. `.id` is the GraphQL ID this attribute wants; `.uuid`
  # is the wrong handle and fails at apply.
  hth_template_ids = {
    for name, t in buildkite_pipeline_template.governed : name => t.id
  }
}

# Pipelines whose step configuration is surrendered to a template. Note what is
# absent: `steps` is never set. It is optional+computed, so leaving it unset lets
# Terraform adopt the template-rendered value instead of putting two sources of
# truth on one attribute.
resource "buildkite_pipeline" "templated" {
  # TRAP 7. No profile-level gate. The declaration map is the switch; an empty
  # var.templated_pipelines is the off state.
  for_each = var.templated_pipelines

  name                       = each.key
  repository                 = each.value.repository
  description                = each.value.description
  default_branch             = each.value.default_branch
  branch_configuration       = each.value.branch_configuration
  cluster_id                 = each.value.cluster_id
  default_team_id            = each.value.default_team_id
  default_timeout_in_minutes = each.value.default_timeout_in_minutes
  maximum_timeout_in_minutes = each.value.maximum_timeout_in_minutes

  # TRAP 2/TRAP 3. lookup() rather than a bare index so the precondition below
  # names the offending pipeline instead of Terraform raising a raw index error.
  # The null branch is unreachable: the precondition refuses an undeclared
  # template, and asserting null here is exactly the detachment TRAP 3 describes.
  pipeline_template_id = lookup(local.hth_template_ids, each.value.template, null)

  # Fork-build restriction carried over from controls 2.2/2.4 so a pipeline
  # created by this pack is never less hardened than one created by that one.
  provider_settings = {
    build_pull_request_forks              = false
    publish_commit_status                 = true
    publish_commit_status_per_step        = true
    skip_builds_for_existing_commits      = true
    cancel_deleted_branch_builds          = true
    prefix_pull_request_fork_branch_names = true
  }

  lifecycle {
    # TRAP 7, enforced rather than narrated. A Buildkite pipeline carries its
    # build history and its webhook URL; both are destroyed with it and neither
    # comes back. Dropping a key from var.templated_pipelines must therefore be a
    # deliberate act, not the side effect of a forgotten -var or an edited tfvars
    # file - so Terraform refuses the destroy at PLAN time. This is the same
    # guard pack 3.11 puts on buildkite_registry. To retire a pipeline on
    # purpose: delete this line, apply, restore it.
    #
    # DELIBERATELY A LITERAL. OpenTofu 1.12 does accept an expression here
    # (measured, not assumed), which is precisely why this must not become
    # `var.profile_level >= 3`: the one forgotten -var would then empty the
    # for_each AND disarm the guard in the same plan, rebuilding the original
    # bug with an extra step.
    prevent_destroy = true

    precondition {
      condition     = contains(keys(var.pipeline_templates), each.value.template)
      error_message = format("Templated pipeline '%s' names template '%s', which is not declared in var.pipeline_templates. This pack refuses to point a pipeline at a console-authored template: an undeclared template's contents can be edited in the UI without drift showing, so the read-only guarantee would be enforcing an ungoverned step list. Bring the template under var.pipeline_templates, or audit it through var.audited_templates and accept that it is not enforced from code.", each.key, each.value.template)
    }

    precondition {
      condition     = each.value.default_team_id != null
      error_message = format("Templated pipeline '%s' sets no default_team_id. The provider documents this attribute as required by the Buildkite API when creating a new pipeline, so the apply would fail at the API with a vaguer message. Supply a team GraphQL ID — pack 2.1 emits them as the `team_ids` output.", each.key)
    }
  }
}

# A template nobody asserts anything about is a template somebody can hollow out
# while every pipeline on it still reports as governed.
check "managed_templates_contain_their_required_steps" {
  assert {
    condition = length(local.hth_templates_missing_required_steps) == 0
    error_message = format(
      "%d template/step-pattern pair(s) are unsatisfied: %s. Pipelines on these templates are held read-only around a step list that no longer contains the mandated step — the failure this control exists to prevent, reached without a single pipeline edit.",
      length(local.hth_templates_missing_required_steps),
      jsonencode(local.hth_templates_missing_required_steps),
    )
  }
}

check "required_step_patterns_are_declared" {
  assert {
    condition = length(var.pipeline_templates) == 0 || length(var.required_step_patterns) > 0
    error_message = format(
      "%d pipeline template(s) are managed but var.required_step_patterns is empty, so nothing asserts what those templates contain. Making a step list read-only guarantees the steps are FIXED, not that they are the RIGHT ones.",
      length(var.pipeline_templates),
    )
  }
}

# TRAP 4, enforced.
check "templates_do_not_silently_delegate_steps_to_the_repository" {
  assert {
    condition = length(local.hth_delegating_templates) == 0
    error_message = format(
      "Template(s) %s run `buildkite-agent pipeline upload`, so their real steps come from the repository's pipeline file rather than from the template. The read-only guarantee stops at the upload boundary and enforcement moves to branch protection and code review on that repository. Name them in var.templates_allowed_to_delegate_upload to record that decision, or inline the mandated step in the template.",
      jsonencode(local.hth_delegating_templates),
    )
  }
}

# WARNING ONLY, and labelled as such. This is a `check` block: Terraform check
# blocks annotate a run, they cannot fail a plan or halt an apply. It is here to
# keep the RECORDED profile level honest, not to guard anything - per TRAP 7
# nothing in this file is gated on profile_level any more, so there is nothing
# left for a guard to stop.
check "template_declarations_record_an_l3_control" {
  assert {
    condition = var.profile_level >= 3 || (length(var.pipeline_templates) == 0 && length(var.templated_pipelines) == 0)
    error_message = format(
      "profile_level is %d, but %d template(s) and %d templated pipeline(s) are declared. Control 3.10 is an L3 control. Those resources ARE created at the level you set - profile level selects WHAT you declare, never whether declared resources survive - so the only thing wrong here is the number: this configuration enforces an L3 control while reporting level %d. Raise profile_level to 3 so the recorded level matches what is applied, or clear the declarations. This message is a warning and does not stop the apply.",
      var.profile_level,
      length(var.pipeline_templates),
      length(var.templated_pipelines),
      var.profile_level,
    )
  }
}

output "pipeline_template_governance" {
  description = "Templates this configuration owns and the pipelines bound to them. `available` is read back off the resource rather than the variable, so a console flip surfaces here."
  value = {
    templates = {
      for name, t in buildkite_pipeline_template.governed : name => {
        uuid                 = t.uuid
        graphql_id           = t.id
        available_to_members = t.available
        configuration_sha256 = sha256(t.configuration)
        delegates_upload     = length(regexall("buildkite-agent\\s+pipeline\\s+upload", t.configuration)) > 0
      }
    }
    pipelines = {
      for name, p in buildkite_pipeline.templated : name => {
        slug                 = p.slug
        template             = var.templated_pipelines[name].template
        pipeline_template_id = p.pipeline_template_id
      }
    }
  }
}
# HTH Guide Excerpt: end standardize-pipeline-steps-with-templates

# HTH Guide Excerpt: begin audit-pipeline-template-governance
# The region above governs what Terraform owns. The residual risk is the template
# authored in the console and the pipeline nobody put under one. Losing a
# mandated step from a template is the same failure as losing it from a pipeline,
# applied to every pipeline on that template at once — and per TRAP 6 Terraform
# can enumerate neither templates nor a pipeline's assignment. What it CAN do is
# re-read a named template and compare it to what was approved.
data "buildkite_pipeline_template" "audited" {
  for_each = var.audited_templates

  name = each.value.name
}

locals {
  # Content drift on a template reviewed once and then left in the console.
  # sha256 over the live configuration is the whole comparison.
  hth_audited_template_drift = [
    for key, t in data.buildkite_pipeline_template.audited : {
      template = t.name
      uuid     = t.uuid
      approved = var.audited_templates[key].approved_configuration_sha256
      observed = sha256(t.configuration)
    }
    if var.audited_templates[key].approved_configuration_sha256 != null
    && sha256(t.configuration) != var.audited_templates[key].approved_configuration_sha256
  ]

  # The same mandated-step assertion applied to templates this configuration does
  # not own. An audited template that never carried the step is as much a finding
  # as one that lost it.
  hth_audited_missing_required_steps = flatten([
    for key, t in data.buildkite_pipeline_template.audited : [
      for pattern in var.required_step_patterns : {
        template = t.name
        pattern  = pattern
      } if length(regexall(pattern, t.configuration)) == 0
    ]
  ])

  # TRAP 1 on the audit side.
  hth_audited_self_assignable = [
    for key, t in data.buildkite_pipeline_template.audited : {
      template = t.name
      uuid     = t.uuid
    } if t.available && !var.audited_templates[key].allow_non_admin_assignment
  ]

  # TRAP 3. Pipelines managed by pack 2.2, which sets no pipeline_template_id and
  # therefore keeps them un-templated on every apply.
  hth_untemplated_pipelines = [
    for name in keys(var.pipelines) : name
    if !contains(var.untemplated_pipelines_allowed, name)
    && !contains(keys(var.templated_pipelines), name)
  ]

  # The same pipeline name claimed by two resource addresses.
  hth_pipeline_address_conflicts = [
    for name in keys(var.templated_pipelines) : name
    if contains(keys(var.pipelines), name)
  ]
}

check "audited_template_configuration_unchanged" {
  assert {
    condition = length(local.hth_audited_template_drift) == 0
    error_message = format(
      "%d audited template(s) no longer hash to their approved configuration: %s. Every pipeline assigned to these templates had its read-only step list rewritten in one edit. Review the change, then update approved_configuration_sha256 in var.audited_templates to re-baseline.",
      length(local.hth_audited_template_drift),
      jsonencode(local.hth_audited_template_drift),
    )
  }
}

check "audited_templates_contain_their_required_steps" {
  assert {
    condition = length(local.hth_audited_missing_required_steps) == 0
    error_message = format(
      "%d audited template/step-pattern pair(s) are unsatisfied: %s. These templates are not owned by this configuration, so nothing stops the next console edit either — bring them under var.pipeline_templates to make their contents enforceable rather than merely observable.",
      length(local.hth_audited_missing_required_steps),
      jsonencode(local.hth_audited_missing_required_steps),
    )
  }
}

check "audited_templates_are_not_self_assignable" {
  assert {
    condition = length(local.hth_audited_self_assignable) == 0
    error_message = format(
      "%d audited template(s) are marked available to non-admin users: %s. Any member who can edit a pipeline can move it onto one of these, which is an escape route out of a stricter template. Set allow_non_admin_assignment on the entry to accept it, or clear the flag in the Buildkite console.",
      length(local.hth_audited_self_assignable),
      jsonencode(local.hth_audited_self_assignable),
    )
  }
}

check "pipeline_not_managed_by_two_resources" {
  assert {
    condition = length(local.hth_pipeline_address_conflicts) == 0
    error_message = format(
      "Pipeline(s) %s appear in BOTH var.pipelines (pack 2.2, buildkite_pipeline.pipelines) and var.templated_pipelines (buildkite_pipeline.templated). Two resource addresses fighting over one pipeline is bad enough; because pipeline_template_id is optional-NOT-computed, the 2.2 address wins by detaching the template. Declare each pipeline in exactly one of the two maps.",
      jsonencode(local.hth_pipeline_address_conflicts),
    )
  }
}

check "pipelines_outside_template_governance" {
  assert {
    condition = length(local.hth_untemplated_pipelines) == 0
    error_message = format(
      "%d pipeline(s) are managed with no template and will have any console-assigned template stripped on apply: %s. Their step configuration stays editable, so a mandated scan step can be removed from them without leaving a Terraform trace. Move them to var.templated_pipelines, or list them in var.untemplated_pipelines_allowed to record the exception.",
      length(local.hth_untemplated_pipelines),
      jsonencode(local.hth_untemplated_pipelines),
    )
  }
}

output "pipeline_template_audit" {
  description = "Live state of every audited template plus the pipelines this configuration leaves outside template governance. A FULL template inventory is not obtainable from Terraform — there is no plural data source — so use the GraphQL/REST API for that."
  value = {
    audited_templates = {
      for key, t in data.buildkite_pipeline_template.audited : key => {
        name                 = t.name
        uuid                 = t.uuid
        graphql_id           = t.id
        available_to_members = t.available
        configuration_sha256 = sha256(t.configuration)
      }
    }
    configuration_drift    = local.hth_audited_template_drift
    missing_required_steps = local.hth_audited_missing_required_steps
    self_assignable        = local.hth_audited_self_assignable
    untemplated_pipelines  = local.hth_untemplated_pipelines
    address_conflicts      = local.hth_pipeline_address_conflicts
  }
}
# HTH Guide Excerpt: end audit-pipeline-template-governance
