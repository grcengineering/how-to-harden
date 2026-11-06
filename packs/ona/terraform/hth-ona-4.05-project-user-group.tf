# HTH Pack Contract: v1
#   control: ona-4.5
#   guide: https://howtoharden.com/guides/ona/#45-review-project-sharing-executable-configuration-and-skill-precedence
#   profile: L2
#   mode: mutating
#   requires: ONA_TOKEN; Terraform>=1.14, Linux; shared versions.tf
# Source: https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/project_role_assignment.md
# Fetched 2026-11-05. No live validation. Review/import/plan before any application.
# Enterprise custom-group sharing. Requires access to a project runner too.
# Grants view/use, not editor/admin. General Access and SCM rights are separate.
variable "shared_project_id" {
  type        = string
  description = "Approved existing project UUID; import existing assignment first."
}
variable "project_users_group_id" {
  type        = string
  description = "Approved existing group UUID; not a reporting team ID."
}
# HTH Guide Excerpt: begin terraform
resource "ona_project_role_assignment" "users" {
  project_id = var.shared_project_id
  group_id   = var.project_users_group_id
  role       = "user"
}
# HTH Guide Excerpt: end terraform
