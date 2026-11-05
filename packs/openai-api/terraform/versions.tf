# Official provider; initialize and validate offline before reviewing any plan.
# Authentication at execution time: OPENAI_ADMIN_KEY, never a .tf variable.
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    openai = {
      source  = "openai/openai"
      version = "= 1.5.0"
    }
  }
}
provider "openai" {}
variable "project_id" {
  type        = string
  description = "Existing API Platform project ID. Import existing managed settings before applying."
}
