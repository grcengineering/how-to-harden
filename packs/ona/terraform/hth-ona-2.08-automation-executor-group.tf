# HTH Pack Contract: v1
#   control: ona-2.8
#   guide: https://howtoharden.com/guides/ona/#28-restrict-shared-automations-and-verify-the-executing-identity
#   profile: L2
#   mode: mutating
#   requires: ONA_TOKEN; Terraform>=1.14, Linux; shared versions.tf
# Source: https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/automation_role_assignment.md
# Fetched 2026-11-05. No live validation. Review/import/plan before any application.
# Enterprise custom-group sharing. Viewer is the least-privileged default.
# Group membership and General Access are separate; inspect every grant.
variable "shared_automation_id" {
  type        = string
  description = "Existing Automation UUID to import/review before adding an assignment."
}
variable "automation_viewer_group_id" {
  type        = string
  description = "Approved existing group UUID; this pack does not grant run/admin access."
}
# HTH Guide Excerpt: begin terraform
resource "ona_automation_role_assignment" "viewers" {
  automation_id = var.shared_automation_id
  group_id      = var.automation_viewer_group_id
  role          = "viewer"
}
# HTH Guide Excerpt: end terraform
