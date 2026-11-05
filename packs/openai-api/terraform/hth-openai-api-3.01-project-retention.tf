# HTH Pack Contract: v1
#   control: openai-api-3.1
#   guide: https://howtoharden.com/guides/openai-api/#31-apply-endpoint-specific-retention-and-residency
#   profile: L2
#   mode: mutating
#   requires: OPENAI_ADMIN_KEY, Terraform, approved retention-program eligibility
# Source: https://developers.openai.com/api/docs/guides/terraform/project-controls
# NIST 800-53 SI-12; cannot enroll an organization or make every tool ZDR-eligible.
variable "approved_retention_type" {
  type        = string
  description = "Contract-approved retention type supported by this project's region."
  validation {
    condition = contains([
      "organization_default", "zero_data_retention", "modified_abuse_monitoring",
      "enhanced_zero_data_retention", "enhanced_modified_abuse_monitoring"
    ], var.approved_retention_type)
    error_message = "Choose an approved supported retention type."
  }
}
# HTH Guide Excerpt: begin project-retention
resource "openai_project_data_retention" "application" {
  project_id = var.project_id
  type       = var.approved_retention_type
}
# Removing this resource from Terraform leaves the remote setting unchanged.
# HTH Guide Excerpt: end project-retention
