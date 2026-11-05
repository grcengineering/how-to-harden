# HTH Pack Contract: v1
#   control: openai-api-2.2
#   guide: https://howtoharden.com/guides/openai-api/#22-allowlist-models-and-hosted-tools
#   profile: L2
#   mode: mutating
#   requires: OPENAI_ADMIN_KEY, Terraform, organization selected-project tool policies
# Source: https://developers.openai.com/api/docs/guides/terraform/project-controls
# NIST 800-53 CM-7, AC-6. Import existing settings; review the saved plan.
variable "approved_model_ids" {
  type        = list(string)
  description = "Explicit model IDs visible to this organization."
  validation {
    condition     = length(var.approved_model_ids) > 0
    error_message = "Choose at least one approved model ID."
  }
}
# HTH Guide Excerpt: begin model-tool-policy
resource "openai_project_model_permissions" "application" {
  project_id = var.project_id
  mode       = "allow_list"
  model_ids  = var.approved_model_ids
}
resource "openai_project_hosted_tool_permissions" "application" {
  project_id               = var.project_id
  file_search_enabled      = false
  web_search_enabled       = false
  image_generation_enabled = false
  mcp_enabled              = false
  code_interpreter_enabled = false
}
# A false tool value fails when the organization enables it for all projects.
# First change that organization's tool policy to selected-project access.
# Removing this hosted-tool resource leaves remote settings unchanged;
# removing the model resource deletes the model-permission configuration.
# HTH Guide Excerpt: end model-tool-policy
