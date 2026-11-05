variable "hth_workflow_inventory_id" {
  type        = string
  default     = ""
  description = "Optional actual existing automation ID for a read-only posture review; empty skips the data-source read."
}

variable "hth_manage_review_workflow" {
  type        = bool
  default     = false
  description = "Explicit opt-in to create/manage the disabled review automation after owner, trigger and tool review."
}

variable "hth_enable_review_workflow" {
  type        = bool
  default     = false
  description = "Separate explicit opt-in to start handling future events. Creation alone keeps it disabled."
}

variable "hth_review_slack_channel_id" {
  type        = string
  default     = ""
  description = "One actual approved Slack channel ID; no broad-channel or generalized action grants are created."
}

variable "hth_review_prompt" {
  type        = string
  default     = "Summarize the requested change for the automation owner and cite relevant source links."
  description = "Reviewed automation task. A prompt is not an authorization boundary; review tools, owner credentials and environment independently."
}
