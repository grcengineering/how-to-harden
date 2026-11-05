# HTH Pack Contract: v1
#   control: openai-api-5.2
#   guide: https://howtoharden.com/guides/openai-api/#52-export-audit-records-and-read-back-security-policy
#   profile: L2
#   mode: read-only
#   requires: OPENAI_ADMIN_KEY, Terraform, existing project
# Sources: https://github.com/openai/terraform-provider-openai/tree/main/docs/data-sources
# NIST 800-53 AU-6, CA-7. Standalone read assessment: copy with versions.tf only.
# HTH Guide Excerpt: begin read-policy-posture
data "openai_project_model_permissions" "observed" { project_id = var.project_id }
data "openai_project_hosted_tool_permissions" "observed" { project_id = var.project_id }
data "openai_project_data_retention" "observed" { project_id = var.project_id }
output "observed_security_policy" {
  value = {
    model_mode       = data.openai_project_model_permissions.observed.mode
    model_ids        = data.openai_project_model_permissions.observed.model_ids
    mcp_enabled      = data.openai_project_hosted_tool_permissions.observed.mcp_enabled
    web_search       = data.openai_project_hosted_tool_permissions.observed.web_search_enabled
    code_interpreter = data.openai_project_hosted_tool_permissions.observed.code_interpreter_enabled
    file_search      = data.openai_project_hosted_tool_permissions.observed.file_search_enabled
    image_generation = data.openai_project_hosted_tool_permissions.observed.image_generation_enabled
    retention_type   = data.openai_project_data_retention.observed.type
  }
}
# HTH Guide Excerpt: end read-policy-posture
