# HTH Pack Contract: v1
#   control: confluent-cloud-1.1
#   guide: https://howtoharden.com/guides/confluent-cloud/#11-separate-workload-identities
#   profile: L1
#   mode: mutating
#   requires: Terraform, Confluent provider, authorized organization access
# Source (reviewed 2026-11-27): https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/service-accounts/create-service-accounts.html
# HTH Guide Excerpt: begin dedicated-service-account
# Review the plan first; applying creates an account without a role binding.
terraform {
  required_providers {
    confluent = {
      source = "confluentinc/confluent"
    }
  }
}

variable "workload_name" {
  type        = string
  description = "Unique service-account display name for the approved workload."
}

resource "confluent_service_account" "workload" {
  display_name = var.workload_name
  description  = "Dedicated identity; grant only reviewed resource-level access."
}
# HTH Guide Excerpt: end dedicated-service-account
