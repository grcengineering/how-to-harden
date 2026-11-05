# HTH Pack Contract: v1
#   control: cursor-cloud-agents-4.1
#   guide: https://howtoharden.com/guides/cursor-cloud-agents/#41-scope-automation-owners-sharing-and-event-triggers
#   profile: L1
#   mode: mutating
#   requires: Terraform >=1.5; cursor/cursor =0.8.0; CURSOR_TOKEN; reviewed owner/environment/channel; explicit management and enable opt-ins
#   changes: optional existing-workflow read; opt-in disabled private-user workflow with a narrow Slack trigger
#   source: https://github.com/cursor/terraform-provider-cursor/blob/v0.8.0/docs/resources/platform_workflow.md
# HTH Guide Excerpt: begin review-automation-authority
# Use with this directory's providers.tf and variables.tf. The native data source
# reads one known ID, not every automation. It also fetches prompt content into
# Terraform state; keep state private even though the output is sensitive.
data "cursor_platform_workflow" "hth_existing" {
  count = length(trimspace(var.hth_workflow_inventory_id)) > 0 ? 1 : 0
  id    = var.hth_workflow_inventory_id
}

output "hth_workflow_observed" {
  sensitive = true
  value = [for workflow in data.cursor_platform_workflow.hth_existing : {
    id                     = workflow.id
    scope                  = workflow.scope
    enabled                = workflow.enabled
    memory_enabled         = workflow.memory_enabled
    disabled_default_tools = workflow.disabled_default_tools
    trigger                = workflow.trigger
    action                 = workflow.action
  }]
}

# OFF by default; even creation keeps enabled=false until a separate opt-in.
# scope=user is private to the owner/admins and runs as that creator.
# team_visible/team_editable_user also run as creator; team/team_editable use
# a team service account. A linked Slack trigger user is not that run identity.
resource "cursor_platform_workflow" "hth_review" {
  count = var.hth_manage_review_workflow ? 1 : 0

  name                   = "HTH owner-reviewed change summary"
  description            = "Private owner-run review; narrow linked-user trigger and no explicit app actions."
  scope                  = "user"
  enabled                = var.hth_enable_review_workflow
  prompt                 = var.hth_review_prompt
  memory_enabled         = false
  skip_install           = true
  disabled_default_tools = ["open_git_pr"]

  trigger = [{
    slack = {
      channels                          = [var.hth_review_slack_channel_id]
      block_unauthenticated_slack_users = true
      message_contains                  = "hth-review:"
      message_contains_is_regex         = false
      top_level_only                    = true
      completion_reaction_mode          = "off"
    }
  }]

  action = []

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = length(trimspace(var.hth_review_slack_channel_id)) > 0 && length(trimspace(var.hth_review_prompt)) > 0
      error_message = "Choose the actual approved channel and reviewed task before creating the automation."
    }
  }
}
# Explicit top_level_only avoids the server's different broad/keyword defaults.
# No read_slack, generalized Slack/Teams posting, MCP, PR approval or reviewer
# action is added. Withholding open_git_pr removes that documented default tool;
# it does not prove all execution tools/network paths are disabled. A prefix and
# linked-user check constrain trigger reach, not instruction or data trust.
# HTH Guide Excerpt: end review-automation-authority
