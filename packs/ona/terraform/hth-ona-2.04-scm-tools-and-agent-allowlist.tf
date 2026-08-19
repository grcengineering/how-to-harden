# =============================================================================
# HTH Pack Contract: v1
#   control: ona-2.4
#   guide:   https://howtoharden.com/guides/ona/#24-govern-scm-tools-and-llm-provider-access
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(read-write PAT)
#
# HTH Ona Control 2.4: Govern SCM Tools and LLM Provider Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5, 3.3 | NIST 800-53 AC-3, CM-7
# Source: https://howtoharden.com/guides/ona/#24-govern-scm-tools-and-llm-provider-access
#
# PROVIDER BLOCK LIVES IN hth-ona-1.01-configure-sso.tf.
#
# Transcribed from https://registry.terraform.io/providers/gitpod-io/ona/0.4.0-beta.1/docs/resources/organization_policies
# (registry v2 provider-doc 13236800, provider-version 105656 = 0.4.0-beta.1).
#
# SINGLETON — merge these attributes into ONE ona_organization_policies resource
# if you adopt more than one pack; two resources managing the same object drift
# forever.
#
# WHY TERRAFORM FOR THIS CONTROL: the three states of the SCM-tools policy
# (everyone / one group / disabled) are expressed by the INTERACTION of two
# fields, and the agent and model allow lists are fail-open sets. Both are the
# kind of thing a console screenshot cannot evidence and a diff can.
#
# TRAPS
#  1. THE THREE STATES ARE ENCODED IN TWO FIELDS.
#       disabled            -> scm_tools_disabled = true
#       one group only      -> scm_tools_disabled = false, scm_tools_allowed_group_id = "<group id>"
#       everyone (default)  -> scm_tools_disabled = false, scm_tools_allowed_group_id = ""
#     Verbatim from the API: "Empty means no restriction (all users can use SCM
#     tools if not disabled)." An empty group id is NOT "nobody" — it is EVERYONE.
#  2. allowed_agent_ids IS FAIL-OPEN. "Empty means all agents are allowed." An
#     empty set is the permissive state, not the restrictive one. The same
#     inversion catches people on codex_model_states.
#  3. codex_model_states IS FAIL-OPEN AND FUTURE-OPEN. "A missing model key is
#     treated as allowed, and future or unlisted models are allowed by default."
#     You cannot express "deny everything except these" here — a model released
#     next month is permitted until someone adds a key. Keys must be the EXACT
#     CodexOpenAIModel enum names (e.g. CODEX_OPEN_AI_MODEL_GPT_5_5); values are
#     only `allowed` or `disabled`. Omit the map to leave model policy unmanaged;
#     `{}` clears every override.
#  4. agent_policy IS AN ATTRIBUTE, NOT A BLOCK. Write `agent_policy = { ... }`.
#  5. SCM TOOLS ARE NOT GIT. Disabling them removes the PR/issue API tools; the
#     agent can still run git commands. This control bounds autonomous repository
#     manipulation, not repository access — for that see pack 4.03.
#  6. LLM PROVIDER CHOICE IS NOT HERE. The provider has no org-scoped LLM
#     resource: ona_runner_llm_integration is keyed by runner_id, and the API's
#     RESOURCE_TYPE_ORGANIZATION_LLM_INTEGRATION enum value has no matching
#     org-level method. The model-backend half of control 2.4 is per-runner or
#     ClickOps; codex_model_states below is the only org-wide model lever.
#  7. scm_tools_allowed_group_id EXPECTS A GROUP ID, not a name. Create the group
#     with ona_group (pack 1.03) and pass its id.
# =============================================================================
#  9. THE THREE ALLOW-LIST VARIABLES HAVE NO DEFAULT. `""`, `[]` and `{}` are
#     not neutral: each RESETS an existing restriction to permissive on apply
#     (empty group id = everyone; empty agent set = all agents; empty model map
#     clears every override). A pack that defaulted them would silently loosen an
#     already-hardened organization, so Terraform now refuses to plan until each
#     one is stated explicitly.

variable "scm_tools_disabled" {
  description = "true removes PR/issue API tools from agents entirely (git commands still work)."
  type        = bool
  default     = false
}

variable "scm_tools_allowed_group_id" {
  description = "Group ID whose members may use SCM tools. EMPTY STRING MEANS EVERYONE, not nobody. Ignored when scm_tools_disabled is true. No default on purpose (TRAP 9): set it deliberately."
  type        = string
}

variable "allowed_agent_ids" {
  description = "Agent IDs users may select. EMPTY SET MEANS ALL AGENTS ARE ALLOWED — this is fail-open. No default on purpose (TRAP 9): set it deliberately."
  type        = set(string)
}

variable "codex_model_states" {
  description = "Map of exact CodexOpenAIModel enum name -> allowed|disabled. Unlisted and future models are ALLOWED; {} clears all overrides. No default on purpose (TRAP 9): set it deliberately."
  type        = map(string)
}

variable "max_subagents_per_environment" {
  description = "Maximum non-terminal sub-agents per environment. Valid range 0-10."
  type        = number
  default     = 3

  validation {
    condition     = var.max_subagents_per_environment >= 0 && var.max_subagents_per_environment <= 10
    error_message = "max_subagents_per_environment must be between 0 and 10."
  }
}

variable "conversation_sharing_policy" {
  description = "Conversation sharing policy. Supported values are disabled and organization."
  type        = string
  default     = "organization"

  validation {
    condition     = contains(["disabled", "organization"], var.conversation_sharing_policy)
    error_message = "conversation_sharing_policy must be one of: disabled, organization."
  }
}

# HTH Guide Excerpt: begin terraform
# SINGLETON: at most one ona_organization_policies per organization (import id "current") —
# merge these attributes with any other ona pack you adopt; two resources drift forever.
resource "ona_organization_policies" "agent_scm_and_models" {
  agent_policy = {
    # State 1: no PR/issue API tools at all.
    scm_tools_disabled = var.scm_tools_disabled

    # State 2: confine SCM tools to one group. "" here means EVERYONE — the empty
    # value is the permissive one, so set a real group id to actually restrict.
    scm_tools_allowed_group_id = var.scm_tools_allowed_group_id

    # Fail-open: an empty set allows every agent. Name the approved agent ids to
    # make this restrictive.
    allowed_agent_ids = var.allowed_agent_ids

    # Fail-open and future-open: unlisted models, including ones released after
    # this apply, are allowed. This can express a deny list, never an allow list.
    codex_model_states = var.codex_model_states

    # Bound the fan-out one agent can create inside a single environment.
    max_subagents_per_environment = var.max_subagents_per_environment

    # "disabled" keeps agent conversations out of org-wide sharing.
    conversation_sharing_policy = var.conversation_sharing_policy
  }
}
# HTH Guide Excerpt: end terraform

output "ona_scm_tools_effective_state" {
  description = "Human-readable resolution of the two-field SCM-tools policy."
  value = (
    var.scm_tools_disabled ? "disabled" :
    var.scm_tools_allowed_group_id == "" ? "everyone (empty group id is permissive)" :
    "restricted to group ${var.scm_tools_allowed_group_id}"
  )
}
