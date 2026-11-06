# HTH Pack Contract: v1
#   control: devin-3.3
#   guide: https://howtoharden.com/guides/devin/#33-bound-automations-oncall-and-auto-triage-authority
#   profile: L2
#   mode: mutating
#   requires: providers.tf; scoped service user; review of exact event schema and full plan
# Source: https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/resources/automation.md
# Source: https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/data-sources/oncall_schemas.md
# Retrieved 2026-11-05. No plan/apply or live credential used by HTH.
# HTH Guide Excerpt: begin bound-automations
variable "org_id" { type = string }
variable "hth_profile_level" {
  type    = number
  default = 1
  validation {
    condition     = contains([1, 2, 3, 4], var.hth_profile_level)
    error_message = "hth_profile_level must be 1..4."
  }
}
variable "create_disabled_automation" {
  type    = bool
  default = false
}
variable "service_user_id" {
  type    = string
  default = ""
}
variable "approved_triggers" {
  description = "Reviewed nonempty trigger array; triggers OR together. No generic unfiltered event default."
  type        = any
  default     = []
}
variable "approved_actions" {
  description = "Reviewed actions, including required enterprise tags; no prompt-as-security-boundary assumption."
  type        = any
  default     = []
}
data "devin_oncall_schemas" "capabilities" {
  org_id = var.org_id
  lifecycle {
    precondition {
      condition     = var.hth_profile_level >= 2
      error_message = "Select hth_profile_level >= 2 before reading automation capabilities."
    }
  }
}
resource "devin_automation" "reviewed_disabled" {
  count                  = var.create_disabled_automation ? 1 : 0
  org_id                 = var.org_id
  name                   = "Reviewed disabled intake"
  enabled                = false
  run_as                 = "service_user"
  run_as_service_user_id = var.service_user_id
  slack_reply_access     = "devin_users"
  teams_reply_access     = "devin_users"
  triggers               = jsonencode(var.approved_triggers)
  actions                = jsonencode(var.approved_actions)
  limits = jsonencode({
    max_acu_limit = 5
    invocations   = { max_per_window = 1, window_seconds = 3600 }
  })
  concurrency = jsonencode({ max_concurrent_runs = 1, max_queue_depth = 0 })
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = length(trimspace(var.service_user_id)) > 0 && length(var.approved_triggers) > 0 && length(var.approved_actions) > 0
      error_message = "Creating even a disabled automation requires a reviewed principal, triggers and actions."
    }
  }
}
# No credentials/URL/secret outputs. Webhook secrets can nevertheless enter state.
# JSON groups are config-authoritative; out-of-band edits are NOT detected as drift.
# Import does not recover them; review the full first post-import plan.
# HTH Guide Excerpt: end bound-automations
