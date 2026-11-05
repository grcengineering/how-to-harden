# HTH Pack Contract: v1
#   control: openai-api-1.1
#   guide: https://howtoharden.com/guides/openai-api/#11-isolate-projects-and-minimize-effective-access
#   profile: L1
#   mode: mutating
#   requires: OPENAI_ADMIN_KEY, Terraform, existing approved group and project
# Source: https://developers.openai.com/api/docs/guides/terraform/projects-and-access
# NIST 800-53 AC-3, AC-6; no benchmark equivalent yet.
variable "approved_group_id" {
  type        = string
  description = "Existing group approved for this API workload; review all other role assignments separately."
}
# HTH Guide Excerpt: begin project-access
resource "openai_project_role" "application" {
  project_id  = var.project_id
  role_name   = "Application response writer"
  description = "Only approved response-generation permission"
  permissions = ["api.responses.write"]
}
resource "openai_project_group_role" "application" {
  project_id = var.project_id
  group_id   = var.approved_group_id
  role_id    = openai_project_role.application.role_id
}
# This assignment is additive: it cannot cancel a broader organization role.
# HTH Guide Excerpt: end project-access
