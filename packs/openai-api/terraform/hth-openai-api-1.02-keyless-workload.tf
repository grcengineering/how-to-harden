# HTH Pack Contract: v1
#   control: openai-api-1.2
#   guide: https://howtoharden.com/guides/openai-api/#12-govern-workload-identities-and-key-lifetimes
#   profile: L2
#   mode: mutating
#   requires: OPENAI_ADMIN_KEY, Terraform, reviewed OIDC issuer/audience/subject
# Sources: https://developers.openai.com/api/docs/guides/terraform/service-accounts
# https://github.com/openai/terraform-provider-openai/blob/main/docs/resources/workload_identity_federation_rule.md
# Available in official provider 1.5.0. NIST 800-53 IA-5, AC-6.
variable "workload_name" { type = string }
variable "oidc_issuer" { type = string }
variable "oidc_audience" { type = string }
variable "oidc_subject" {
  type        = string
  description = "Exact reviewed OIDC sub; for GitHub use a protected branch/environment subject, not a repository-wide wildcard."
}
# HTH Guide Excerpt: begin keyless-workload
resource "openai_project_service_account" "workload" {
  project_id = var.project_id
  name       = var.workload_name
}
# The provider creates the identity with no API key and no default role.
resource "openai_group" "workload" { name = "${var.workload_name}-access" }
resource "openai_group_user" "workload" {
  group_id = openai_group.workload.group_id
  user_id  = openai_project_service_account.workload.id
}
resource "openai_project_group_role" "workload" {
  project_id = var.project_id
  group_id   = openai_group.workload.group_id
  role_id    = openai_project_role.application.role_id
}
resource "openai_workload_identity_provider" "workload" {
  name     = "${var.workload_name}-oidc"
  issuer   = var.oidc_issuer
  audience = var.oidc_audience
  enabled  = true
}
resource "openai_workload_identity_federation_rule" "workload" {
  workload_identity_provider_id = openai_workload_identity_provider.workload.workload_identity_provider_id
  project_id                    = var.project_id
  service_account_id            = openai_project_service_account.workload.service_account_id
  attribute_matchers            = { sub = var.oidc_subject }
  enabled                       = true
  permissions = {
    type   = "restricted"
    scopes = ["api.responses.write"]
  }
}
# HTH Guide Excerpt: end keyless-workload
