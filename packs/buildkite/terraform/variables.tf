# =============================================================================
# Buildkite Hardening Code Pack - Variables
# How to Harden (howtoharden.com)
#
# Profile levels are cumulative: L2 includes L1, L3 includes L1+L2.
# Usage: terraform apply -var="profile_level=1"
# =============================================================================

# -----------------------------------------------------------------------------
# Profile Level
# -----------------------------------------------------------------------------

variable "profile_level" {
  description = "Hardening profile level: 1 = L1 (Crawl), 2 = L2 (Walk), 3 = L3 (Run)"
  type        = number
  default     = 1

  validation {
    condition     = var.profile_level >= 1 && var.profile_level <= 3
    error_message = "Profile level must be 1, 2, or 3."
  }
}

# -----------------------------------------------------------------------------
# Buildkite Provider Configuration
# -----------------------------------------------------------------------------

variable "buildkite_organization" {
  description = "Buildkite organization slug (from your organization URL)"
  type        = string
}

variable "buildkite_api_token" {
  description = "Buildkite API token with GraphQL and REST API access"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

variable "enforce_2fa" {
  description = "Whether to require two-factor authentication for all organization members"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.1: Team Permissions
# -----------------------------------------------------------------------------

variable "teams" {
  description = "Map of teams to create with their configurations"
  type = map(object({
    description         = optional(string, "")
    privacy             = optional(string, "VISIBLE")
    default_team        = optional(bool, false)
    default_member_role = optional(string, "MEMBER")

    # All five privileges are optional + computed in the provider. Every one of
    # them is declared here so an omission in tfvars still resolves to an explicit
    # false rather than to "whatever the console currently says".
    members_can_create_pipelines  = optional(bool, false)
    members_can_create_registries = optional(bool, false)
    members_can_create_suites     = optional(bool, false)

    # DESTRUCTIVE — package and registry deletion. Default false; granting either
    # hands a non-admin the ability to erase published artifacts and their
    # attestations, which no API call undoes.
    members_can_destroy_packages   = optional(bool, false)
    members_can_destroy_registries = optional(bool, false)
  }))
  default = {
    platform = {
      description                    = "Platform engineering team"
      privacy                        = "VISIBLE"
      default_team                   = false
      default_member_role            = "MEMBER"
      members_can_create_pipelines   = true
      members_can_create_registries  = true
      members_can_create_suites      = true
      members_can_destroy_packages   = false
      members_can_destroy_registries = false
    }
    developers = {
      description                    = "Development team with read and build access"
      privacy                        = "VISIBLE"
      default_team                   = true
      default_member_role            = "MEMBER"
      members_can_create_pipelines   = false
      members_can_create_registries  = false
      members_can_create_suites      = false
      members_can_destroy_packages   = false
      members_can_destroy_registries = false
    }
    security = {
      description                    = "Security team with audit access"
      privacy                        = "SECRET"
      default_team                   = false
      default_member_role            = "MEMBER"
      members_can_create_pipelines   = false
      members_can_create_registries  = false
      members_can_create_suites      = false
      members_can_destroy_packages   = false
      members_can_destroy_registries = false
    }
  }
}

# -----------------------------------------------------------------------------
# Section 2.2: Pipeline Permissions (L2)
# -----------------------------------------------------------------------------

variable "pipelines" {
  description = "Map of pipelines to create with hardened configurations"
  type = map(object({
    repository                 = string
    description                = optional(string, "")
    default_branch             = optional(string, "main")
    branch_configuration       = optional(string, null)
    skip_intermediate_builds   = optional(bool, true)
    cancel_intermediate_builds = optional(bool, true)
    cluster_id                 = optional(string, null)
    default_timeout_in_minutes = optional(number, 60)
    maximum_timeout_in_minutes = optional(number, 120)
    allow_rebuilds             = optional(bool, true)

    # PUBLIC | PRIVATE. Defaults to PRIVATE because the provider attribute is
    # optional + computed: leaving it out of tfvars would make Terraform adopt the
    # server's current value instead of asserting one, and a console flip to PUBLIC
    # would then never be reverted.
    visibility = optional(string, "PRIVATE")
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in var.pipelines : contains(["PUBLIC", "PRIVATE"], p.visibility)
    ])
    error_message = "pipeline visibility must be PUBLIC or PRIVATE (the provider rejects any other value)."
  }
}

variable "pipeline_team_access" {
  description = "Map of pipeline-to-team access grants (key: 'pipeline_key-team_key')"
  type = map(object({
    pipeline_key = string
    team_key     = string
    access_level = string # READ_ONLY, BUILD_AND_READ, or MANAGE_BUILD_AND_READ
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 3.1: Agent Tokens
# -----------------------------------------------------------------------------

variable "agent_tokens" {
  description = <<-EOT
    Cluster-scoped agent registration tokens, keyed by a stable label.
      cluster              — name of an EXISTING cluster; null falls back to var.agent_token_cluster_name.
      allowed_ip_addresses — CIDR allowlist. EMPTY MEANS UNRESTRICTED, which pack 3.1 refuses to plan
                             unless agent_token_require_ip_allowlist is set false.
      rotation_id          — generation marker for THIS entry, stamped into the token's description.
                             Set it when you add the entry; do NOT edit it afterwards. Editing it in
                             place only relabels the incumbent token — it mints nothing.
    ROTATION IS TWO APPLIES, NOT AN EDIT. Buildkite tokens have no Terraform-settable expiry, and the
    secret is returned exactly once — from the apply that creates it — so a same-apply replacement
    revokes the incumbent before the operator can have distributed the replacement. Instead:
    (1) ADD a second entry with a new map key, the same cluster and description, and rotation_id
    bumped, then apply — both tokens are now valid and the new secret is in the output;
    (2) roll the agent hosts onto the new secret and confirm every one has re-registered;
    (3) DELETE the old entry and apply again. Pack 3.1's check block reports any rotation left
    unfinished. To revoke immediately (leaked token), delete the entry and apply — the plan reads
    "1 to destroy", and note that revocation does not disconnect already-connected agents.
    Defaults to {} so no unrestricted token is ever created by accident.
  EOT
  type = map(object({
    description          = string
    cluster              = optional(string, null)
    allowed_ip_addresses = optional(list(string), [])
    rotation_id          = optional(string, "1")
  }))
  default = {}
}

variable "agent_token_cluster_name" {
  description = "Cluster name used for any agent_tokens entry that leaves `cluster` null. Buildkite auto-provisions a cluster literally named \"Default cluster\"; this selector is case- and space-sensitive and a mismatch fails the plan rather than creating anything."
  type        = string
  default     = "Default cluster"
}

variable "agent_token_require_ip_allowlist" {
  description = "Fail the plan when an agent token declares no allowed_ip_addresses. Buildkite's own default is unrestricted, so leaving this true is what converts silence into a visible failure. Set false only to accept an unrestricted registration token deliberately."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.2: Agent Clusters (L2)
# -----------------------------------------------------------------------------

variable "clusters" {
  description = <<-EOT
    Map of agent clusters to create for environment isolation. Control 3.2 is an
    L2 control, but this map — not profile_level — is what switches pack 3.2 on:
    the resource is no longer gated on profile_level, because a profile-level
    gate makes a level DOWNGRADE destroy the cluster, its queues and its
    cluster-scoped agent tokens.

    DEFAULTS TO EMPTY, DELIBERATELY. This used to default to three clusters
    (production/development/security). Combined with the README's bare
    `terraform apply`, that meant adopting any single control in this directory
    silently created three clusters nobody asked for. The worked
    three-environment example is preserved in terraform.tfvars.example — copy it
    from there and edit it, so creating a cluster is always something you wrote
    down.
  EOT
  type = map(object({
    description = optional(string, "")
    color       = optional(string, null)
    emoji       = optional(string, null)
  }))
  default = {}
}

variable "cluster_queues" {
  description = "Map of cluster queues to create (L2+). Key format: 'cluster_key-queue_name'"
  type = map(object({
    cluster_key = string
    key         = string
    description = optional(string, "")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "allowed_api_ip_addresses" {
  description = "List of IP addresses in CIDR format allowed to access the Buildkite API (L3). Empty list allows all."
  type        = list(string)
  default     = []
}

# ─── Control 2.3 — administrative access ────────────────────────────────────
variable "max_org_members" {
  description = "Upper bound on organization membership. The check block in pack 2.3 fails the plan when the real roster exceeds this, turning silent membership growth into a review."
  type        = number
  default     = 25
}

variable "team_maintainers" {
  description = "Explicitly declared team maintainers, keyed by a stable label. Declaring them means an out-of-band promotion shows up as drift."
  type = map(object({
    team_id = string
    user_id = string
  }))
  default = {}
}

variable "team_members" {
  description = "Explicitly declared non-maintainer team members, keyed by a stable label."
  type = map(object({
    team_id = string
    user_id = string
  }))
  default = {}
}

# ─── Control 3.3 — agent infrastructure ─────────────────────────────────────
variable "agent_clusters" {
  description = "Agent clusters, one per trust boundary. Key is the cluster name."
  type = map(object({
    description = optional(string, "Managed by HTH pack 3.3")
    emoji       = optional(string, ":lock:")
    color       = optional(string, "#0F172A")
  }))
  default = {}
}

variable "agent_queues" {
  description = "Queues within the declared clusters. `cluster` must be a key of agent_clusters. `paused` maps to dispatch_paused, which is optional+COMPUTED: the default is null (attribute left unset) so a routine apply can never revert a queue pause a responder applied during an incident. See control 4.2 for the containment surface."
  type = map(object({
    cluster     = string
    key         = string
    description = optional(string, "Managed by HTH pack 3.3")
    paused      = optional(bool, null)
  }))
  default = {}
}

variable "agent_allowed_cidrs" {
  description = "Egress CIDRs permitted to register agents. LOCKOUT-CAPABLE: an agent outside this list cannot register, and a wrong entry strands the entire cluster. Leave empty to apply no IP restriction rather than guessing."
  type        = list(string)
  default     = []
}

# ─── Control 2.7 — cross-pipeline authorization (Buildkite Rules) ────────────
variable "cross_pipeline_rules" {
  description = "Approved cross-pipeline grants. Each entry is a standing exception to cluster and visibility isolation: a rule overrides the usual trigger-step permission checks and works across clusters and across public/private boundaries. Prefer pipeline UUIDs over slugs — a slug can be reused by a recreated pipeline, which silently inherits the grant."
  type = map(object({
    type            = string
    source_pipeline = string
    target_pipeline = string
    conditions      = optional(list(string), [])
    description     = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in var.cross_pipeline_rules :
      contains(["pipeline.trigger_build.pipeline", "pipeline.artifacts_read.pipeline"], r.type)
    ])
    error_message = "Rule type must be pipeline.trigger_build.pipeline or pipeline.artifacts_read.pipeline — the only two types Buildkite implements."
  }
}

variable "unconditional_rule_exceptions" {
  description = "Keys of cross_pipeline_rules permitted to carry no conditions. Buildkite treats an absent conditions array as 'allowed in all cases', so a conditionless rule is a permanent unscoped grant. Naming a key here is the record that the grant was reviewed."
  type        = list(string)
  default     = []
}

variable "reviewed_rules" {
  description = "Rules created outside Terraform that have been reviewed and accepted, keyed by a stable label. Discover UUIDs with GET /v2/organizations/{org}/rules; the provider offers no data source that enumerates every rule. source_uuid/target_uuid record the pipelines the grant was approved between, so a console re-point shows up as a check failure."
  type = map(object({
    uuid        = string
    source_uuid = string
    target_uuid = string
  }))
  default = {}
}

# ─── Control 3.7 — delegated cluster administration ─────────────────────────
variable "cluster_maintainers" {
  description = "Scoped cluster administration grants, keyed by a stable label. `cluster` is the cluster NAME (resolved to its uuid via the data source). Set exactly one of team_uuid or user_uuid; a team grant re-evaluates against live membership, a user grant survives offboarding. Maintainers hold agent-token, queue AND secret authority over their cluster."
  type = map(object({
    cluster   = string
    team_uuid = optional(string)
    user_uuid = optional(string)
  }))
  default = {}
}

variable "audited_clusters" {
  description = "Cluster names to audit for out-of-band maintainers, in addition to any cluster named in cluster_maintainers. Empty means only clusters this configuration grants into are audited."
  type        = list(string)
  default     = []
}

variable "additional_approved_maintainer_uuids" {
  description = "Actor UUIDs (user or team) accepted as cluster maintainers without a Terraform declaration. Every UUID here is an exception to the 'declared in code' rule and should be reviewed on the same cadence as the cluster."
  type        = list(string)
  default     = []
}

variable "max_direct_user_maintainers" {
  description = "Upper bound on cluster maintainers granted to an individual user rather than a team. Defaults to 0: user grants are the ones that outlive offboarding. Raise deliberately to record a break-glass individual."
  type        = number
  default     = 0
}

# ─── Control 2.5 — Portals (scoped GraphQL instead of a general token) ───────
variable "portals" {
  description = "Portals to declare, keyed by portal name. Each mints a LONG-LIVED, ADMINISTRATOR-LEVEL service token scoped to its stored GraphQL document — keep the query as narrow as the integration allows. `allowed_cidrs` is list-shaped here for readability and is joined into the provider's space-delimited string; leaving it empty means the portal is callable from any address."
  type = map(object({
    slug           = string
    query          = string
    description    = optional(string, "Managed by HTH pack 2.5")
    allowed_cidrs  = optional(list(string), [])
    user_invokable = optional(bool, false)
  }))
  default = {}
}

# ─── Control 3.10 — pipeline templates (Enterprise) ─────────────────────────
variable "pipeline_templates" {
  description = <<-EOT
    Pipeline templates this configuration owns, keyed by template name. Assigning a
    template makes the adopting pipeline's step configuration READ-ONLY, which is what
    stops a pipeline editor deleting a mandated security step.
      configuration — the template's YAML step configuration, including its own `steps:`
                      key. A template whose steps are only `buildkite-agent pipeline
                      upload` enforces nothing in Buildkite: the real steps then come
                      from the repository and the control boundary moves to branch
                      protection. Pack 3.10 fails the plan on that unless the template is
                      named in var.templates_allowed_to_delegate_upload.
      available     — whether NON-ADMINS may attach this template to a pipeline of their
                      own. Defaults to false. The attribute is optional+computed in the
                      provider, so pack 3.10 always sets it explicitly; otherwise a
                      console flip is silently adopted as desired state. Every `true` is
                      a downgrade path out of a stricter template.
  EOT
  type = map(object({
    configuration = string
    description   = optional(string, "Managed by HTH pack 3.10")
    available     = optional(bool, false)
  }))
  default = {}
}

variable "required_step_patterns" {
  description = "Regex patterns that must each match every template's configuration — typically the key or command of a mandated security step. Pack 3.10 refuses to manage templates while this is empty: making a step list read-only guarantees the steps are FIXED, not that they are the RIGHT ones, and only this assertion closes that gap."
  type        = list(string)
  default     = ["hth-security-scan"]
}

variable "templates_allowed_to_delegate_upload" {
  description = "Template names permitted to run `buildkite-agent pipeline upload` and thereby source their real steps from the repository instead of the template. Each entry is the record that somebody accepted the control boundary moving to that repository's branch protection and code review. Command spelling is identical on buildkite-agent v3 and v4."
  type        = list(string)
  default     = []
}

variable "templated_pipelines" {
  description = <<-EOT
    Pipelines whose step configuration is surrendered to a template, keyed by pipeline
    name. `template` must be a key of var.pipeline_templates — pack 3.10 deliberately
    refuses to point a pipeline at a console-authored template, whose contents can be
    edited in the UI without any drift showing.

    Owned here rather than in var.pipelines (pack 2.2) because
    buildkite_pipeline.pipeline_template_id is optional-NOT-computed: a resource that
    omits it asserts null and STRIPS a console-assigned template on every apply. A name
    must not appear in both maps; pack 3.10 fails the plan if it does.

    default_team_id is required by the Buildkite API when a pipeline is created, so an
    entry that leaves it null fails the plan with a message naming the pipeline rather
    than failing at the API with a vaguer one. Pack 2.1 emits candidate IDs as `team_ids`.

    There is deliberately no `steps` field — a templated pipeline's steps are read-only,
    so declaring both would put two sources of truth on one attribute.
  EOT
  type = map(object({
    repository                 = string
    template                   = string
    description                = optional(string, "Managed by HTH pack 3.10")
    default_branch             = optional(string, "main")
    branch_configuration       = optional(string)
    cluster_id                 = optional(string)
    default_team_id            = optional(string)
    default_timeout_in_minutes = optional(number, 60)
    maximum_timeout_in_minutes = optional(number, 120)
  }))
  default = {}
}

variable "audited_templates" {
  description = <<-EOT
    Templates to re-read and compare against an approved baseline, keyed by a stable
    label. Covers templates authored in the console that this configuration does not own.
    Terraform cannot enumerate templates (there is no plural data source) and cannot read
    a pipeline's assigned template (the buildkite_pipeline DATA SOURCE exposes no
    pipeline_template_id), so a full inventory needs the GraphQL/REST API — this variable
    audits the templates you name.
      name                          — the template's name in Buildkite.
      approved_configuration_sha256 — sha256 of the approved configuration string. Null
                                      skips the drift assertion. Re-baseline deliberately
                                      after reviewing a change.
      allow_non_admin_assignment    — accept that this template is self-assignable by
                                      non-admins. Defaults to false.
  EOT
  type = map(object({
    name                          = string
    approved_configuration_sha256 = optional(string)
    allow_non_admin_assignment    = optional(bool, false)
  }))
  default = {}
}

variable "untemplated_pipelines_allowed" {
  description = "Names of pipelines in var.pipelines (pack 2.2) accepted as having no template. Pack 2.2 sets no pipeline_template_id, so its pipelines are not merely untemplated — any console-assigned template is actively stripped on each apply and their steps stay editable. Each entry records that exception."
  type        = list(string)
  default     = []
}

variable "templated_pipeline_default_team_id" {
  description = "Team GraphQL ID assigned to every pipeline pack 3.10 creates. The provider documents default_team_id as \"required by the Buildkite API when creating a new pipeline\", and the team named here is granted 'Manage Build and Read'; further associations go through buildkite_pipeline_team. Pack 2.1 emits usable IDs as its `team_ids` output. Null fails the plan with that explanation rather than failing later at the API with a vaguer one."
  type        = string
  default     = null
}

variable "mandated_template_steps_yaml" {
  description = "Steps prepended to EVERY template in var.pipeline_templates, as YAML list items indented at least two spaces (no `steps:` key — pack 3.10 supplies it). This is the block a template author cannot forget: removing it is a reviewed variable edit rather than a quiet deletion inside one pipeline."
  type        = string
  default     = <<EOT
  - label: ":lock: Security scan"
    key: "hth-security-scan"
    command: "buildkite-agent pipeline upload .buildkite/security-scan.yml"
EOT
}

variable "max_assignable_templates" {
  description = "Upper bound on templates carrying available = true (attachable by non-admins). Defaults to 0: an assignable permissive template lets a pipeline editor reach the same result as deleting a step, without editing one. Raise deliberately, and only for templates that themselves carry the mandated steps."
  type        = number
  default     = 0
}

variable "audited_template_names" {
  description = "Names of pipeline templates to re-read and assert on, including console-authored templates this configuration does not own. Terraform cannot enumerate templates (no plural data source) and cannot read a pipeline's assigned template (the buildkite_pipeline DATA SOURCE exposes no pipeline_template_id), so a full inventory needs the GraphQL/REST API — this audits the templates you name."
  type        = list(string)
  default     = []
}

variable "mandated_step_markers" {
  description = "Literal substrings that must appear in every audited template's configuration — typically the key or command of the mandated security step. A template that lost its mandated step is the same failure as a pipeline that lost it, applied at once to every pipeline assigned that template."
  type        = list(string)
  default     = ["hth-security-scan"]
}

# ─── Control 3.11 — inbound OIDC trust (registries, test suites) ─────────────
# Shapes match the encoder in pack 3.11 exactly. A claim rule is a MATCHER object,
# not a bare string: the vendor's policy grammar supports equals / not_equals /
# in / not_in / matches, and the pack always emits explicit matcher form because
# the scalar shorthand is only legal when the entire rule is a scalar.

variable "registry_oidc_policies" {
  description = <<-EOT
    Package registries whose PUBLISH authority is expressed as an OIDC policy rather than as
    possession of a long-lived token. Keyed by REGISTRY NAME (the key becomes buildkite_registry.name).
      ecosystem   — REQUIRED by the provider and FORCE-NEW; changing it destroys the registry and
                    every package in it, which pack 3.11 refuses via prevent_destroy.
      team_uuids  — REQUIRED. UUIDs, not GraphQL IDs (buildkite_team.<x>.uuid). This is the HUMAN
                    access path; the policy is the MACHINE access path. A tight policy beside a wide
                    team list is one closed door next to an open one.
      statements  — evaluated in order, FIRST MATCH WINS. An empty list encodes to "" — the
                    documented way to assert "no inbound OIDC trust" — rather than leaving a
                    console-authored policy in place unmanaged.
    A statement granting write_packages or delete_packages must constrain pipeline_slug or
    repository; organization_slug narrows nothing, because every pipeline in the org asserts it.
  EOT
  type = map(object({
    ecosystem   = string
    team_uuids  = list(string)
    description = optional(string, "Managed by HTH pack 3.11")
    emoji       = optional(string)
    color       = optional(string)

    statements = list(object({
      issuer = string
      scopes = list(string)
      claims = optional(map(object({
        equals     = optional(string)
        not_equals = optional(string)
        any_of     = optional(list(string))
        none_of    = optional(list(string))
        matches    = optional(string)
      })), {})
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.registry_oidc_policies : length(r.team_uuids) > 0 && r.ecosystem != ""])
    error_message = "buildkite_registry requires a non-empty ecosystem and at least one team_uuid; the provider will not plan without them."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.registry_oidc_policies : [
        for st in r.statements : length(st.scopes) > 0 && alltrue([
          for s in st.scopes : contains(["read_packages", "write_packages", "delete_packages"], s)
        ])
      ]
    ]))
    error_message = "Registry OIDC scopes must be drawn from read_packages, write_packages, delete_packages. The registry and test-suite scope vocabularies are disjoint — a suite scope here is silently meaningless."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.registry_oidc_policies : [
        for st in r.statements : [
          for name, rule in st.claims :
          contains(["organization_slug", "pipeline_slug", "build_branch", "repository", "actor"], name) &&
          length(compact([rule.equals, rule.not_equals, rule.matches])) + (rule.any_of == null ? 0 : length(rule.any_of)) + (rule.none_of == null ? 0 : length(rule.none_of)) > 0
        ]
      ]
    ]))
    error_message = "Every claim must be one of organization_slug, pipeline_slug, build_branch, repository, actor, and must set at least one matcher (equals / not_equals / any_of / none_of / matches). oidc_policy reaches the provider as an opaque string, so this validation is the only place a typo'd claim or an empty rule is caught."
  }

  validation {
    condition     = alltrue([for r in var.registry_oidc_policies : alltrue([for st in r.statements : st.issuer != ""])])
    error_message = "Every statement needs a non-empty issuer. Buildkite's own agent issuer is https://agent.buildkite.com — this is inbound federation FROM your pipelines, not from your IdP."
  }
}

variable "test_suite_oidc_policies" {
  description = <<-EOT
    Test suites whose inbound authentication is governed by an OIDC policy. Keyed by SUITE NAME.
      default_branch / team_owner_id — both REQUIRED by the provider. team_owner_id is a GraphQL ID,
                                       the opposite namespace from registry team_uuids.
      statements                     — same grammar as registry_oidc_policies, different scope
                                       vocabulary (read_suites / write_uploads / read_test_plan /
                                       write_test_plan).
    buildkite_test_suite.oidc_policy is Optional + COMPUTED, so omitting it leaves a console-authored
    policy in place silently; the pack always asserts a value, and an empty statement list encodes "".
    Adopting OIDC does NOT revoke the suite's api_token — see var.suite_api_tokens_rotated.
  EOT
  type = map(object({
    default_branch   = string
    team_owner_id    = string
    application_name = optional(string)
    emoji            = optional(string)
    color            = optional(string)

    statements = list(object({
      issuer = string
      scopes = list(string)
      claims = optional(map(object({
        equals     = optional(string)
        not_equals = optional(string)
        any_of     = optional(list(string))
        none_of    = optional(list(string))
        matches    = optional(string)
      })), {})
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.test_suite_oidc_policies : s.default_branch != "" && s.team_owner_id != ""])
    error_message = "buildkite_test_suite requires a non-empty default_branch and team_owner_id; the provider will not plan without them."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.test_suite_oidc_policies : [
        for st in s.statements : length(st.scopes) > 0 && alltrue([
          for sc in st.scopes : contains(["read_suites", "write_uploads", "read_test_plan", "write_test_plan"], sc)
        ])
      ]
    ]))
    error_message = "Test suite OIDC scopes must be drawn from read_suites, write_uploads, read_test_plan, write_test_plan. Registry scopes are a disjoint vocabulary and mean nothing here."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.test_suite_oidc_policies : [
        for st in s.statements : [
          for name, rule in st.claims :
          contains(["organization_slug", "pipeline_slug", "build_branch", "repository", "actor"], name) &&
          length(compact([rule.equals, rule.not_equals, rule.matches])) + (rule.any_of == null ? 0 : length(rule.any_of)) + (rule.none_of == null ? 0 : length(rule.none_of)) > 0
        ]
      ]
    ]))
    error_message = "Every claim must be one of organization_slug, pipeline_slug, build_branch, repository, actor, and must set at least one matcher (equals / not_equals / any_of / none_of / matches)."
  }

  validation {
    condition     = alltrue([for s in var.test_suite_oidc_policies : alltrue([for st in s.statements : st.issuer != ""])])
    error_message = "Every statement needs a non-empty issuer."
  }
}

variable "suite_api_tokens_rotated" {
  description = "Keys of test_suite_oidc_policies whose static api_token has been rotated in the console AND removed from the pipeline that used it. OIDC ADDS an authentication path; it does not close the old one, and the provider exposes no attribute to revoke or rotate api_token. Until a suite is listed here, pack 3.11 reports it as still reachable by a standing credential."
  type        = list(string)
  default     = []
}

variable "audited_registry_slugs" {
  description = "Registry slugs to audit for a missing OIDC policy, covering registries this configuration does not manage. buildkite_registry.slug is COMPUTED — Buildkite derives it from the name — so read these out of the console URL. There is NO plural data source for registries, so anything absent from this list is invisible to the audit; reconciling it against the Package Registries page is a manual control."
  type        = list(string)
  default     = []
}

variable "audited_test_suite_slugs" {
  description = "Test suite slugs to audit for a missing OIDC policy, covering suites this configuration does not manage. Read the slug from the console URL. A suite with no policy accepts uploads on the strength of its static api_token alone."
  type        = list(string)
  default     = []
}

# ─── Control 4.2 — build-fleet containment (incident response) ──────────────
variable "containment_queues" {
  description = <<-EOT
    Cluster queues whose dispatch state is part of the incident-response surface,
    keyed by a stable label. `cluster` is the cluster NAME (resolved to its GraphQL
    id via the data source; the queue resource takes the id, not the uuid).

    break_glass_pause is DELIBERATELY tri-state and defaults to null:
      null   -> attribute left UNSET. Terraform adopts whatever Buildkite reports,
                so a pause a responder applied in the console SURVIVES the next
                apply. This is the only safe default: dispatch_paused is
                optional+computed, so a `false` here would re-enable dispatch on a
                queue somebody paused during an incident.
      true   -> pause dispatch. New jobs stop being handed out; jobs already
                running on an agent are unaffected — stop the agents too.
      false  -> resume dispatch, but ONLY when the key also appears in
                var.acknowledged_resume_queues. Otherwise it is coerced back to
                null and reported, because an unreviewed `false` is how a routine
                apply un-contains a fleet.

    Queues that already exist must be imported before the first apply — the import
    id is "<queue GraphQL id>,<cluster uuid>". Defaults to {} so this pack creates
    nothing until you name the queues you actually intend to govern.
  EOT
  type = map(object({
    cluster           = string
    key               = string
    description       = optional(string, "Managed by HTH pack 4.2 — containment surface")
    break_glass_pause = optional(bool, null)
  }))
  default = {}
}

variable "break_glass_pause_all" {
  description = "Fleet-wide break glass: pause dispatch on EVERY queue in var.containment_queues in one change. Defaults to false, which does NOT unpause anything — false leaves each queue on its own break_glass_pause value, and an unset value stays unset. This is the switch you flip in an incident; turning it back off resumes nothing on its own, which is intentional so that restoring service is always a separate, deliberate act."
  type        = bool
  default     = false
}

variable "acknowledged_resume_queues" {
  description = "Keys of containment_queues permitted to actually resume dispatch (break_glass_pause = false). A resume returns work to a fleet that was contained for a reason; naming the key here is the record that someone decided the hosts were rebuilt and fresh tokens issued, rather than a stale `false` left in a variables file."
  type        = list(string)
  default     = []
}

# ─── Control 3.5 — cluster-scoped build secrets ─────────────────────────────
variable "cluster_secrets" {
  description = <<-EOT
    Cluster-scoped Buildkite secrets, keyed by a stable label.
      cluster          — name of an EXISTING cluster; resolved to its uuid by pack 3.5,
                         because buildkite_cluster_secret.cluster_id takes the plain UUID
                         while the agent-token and default-queue resources take the GraphQL id.
      key              — the secret's key in Buildkite. Immutable: a rename is a
                         create-plus-delete. Must start with a letter, contain only letters,
                         digits and underscores, be at most 255 characters, and must not
                         begin with `bk` or `buildkite` (reserved, case-insensitive).
      value_wo_version — STRING, not a number. The write-only value is never read back, so
                         this is the ONLY signal Terraform has that the material rotated.
                         Set it to the upstream secret manager's version identifier.
      policy_rules     — list of access-policy rules; each rule is a map of claim -> value,
                         and a build may read the secret when it satisfies a rule. Claims:
                         first-party (Buildkite-issued) pipeline_id, build_source,
                         cluster_queue_id; third-party (user-supplied) pipeline_slug,
                         build_branch, build_creator, build_creator_team, cluster_queue_key.
                         An empty list means no policy and is rejected by pack 3.5.
      production       — marks the secret as a production credential, checked against
                         production_secret_clusters.
    DELIBERATELY NOT sensitive and NOT ephemeral: this map drives for_each, and Terraform
    rejects sensitive or ephemeral values as for_each arguments. It therefore carries no
    secret material — that lives in cluster_secret_values.
  EOT
  type = map(object({
    cluster          = string
    key              = string
    value_wo_version = string
    policy_rules     = optional(list(map(string)), [])
    description      = optional(string)
    production       = optional(bool, false)
  }))
  default = {}
}

variable "cluster_secret_values" {
  description = "Secret material for var.cluster_secrets, keyed identically. EPHEMERAL: pack 3.5 passes each value to Buildkite through the resource's write-only `value_wo` argument, so it is never written to a plan file or to state and cannot be recovered by anyone holding state. Supply from an ephemeral resource, an uncommitted -var-file, or TF_VAR_ variables sourced from your secret manager. Note the size ceiling is disputed: the Terraform provider documents 8 KB while Buildkite's own secrets documentation says 32 KB — design to the lower figure."
  type        = map(string)
  ephemeral   = true
  sensitive   = true
  default     = {}
}

variable "require_first_party_claim" {
  description = "Fail the plan when any cluster secret policy rule is built only from third-party claims (pipeline_slug, build_branch, build_creator, build_creator_team, cluster_queue_key). Those values are supplied by users or third-party tools: a slug is reusable by a pipeline recreated after the original was deleted, and a branch name is chosen by anyone who can push. Leave true so a soft boundary has to be accepted deliberately rather than by omission; the audit check reports the same finding either way."
  type        = bool
  default     = true
}

variable "production_secret_clusters" {
  description = "Cluster names permitted to hold secrets marked `production = true` in var.cluster_secrets. Implements control 3.5 Step 4: a production credential stored in a development cluster is reachable by every agent registered to that cluster, which undoes the isolation control 3.2 establishes. Empty disables the check rather than guessing which of your clusters is production."
  type        = list(string)
  default     = []
}
