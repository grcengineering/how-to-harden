# HTH Pack Contract: v1
#   control: mulesoft-anypoint-2.1
#   guide: https://howtoharden.com/guides/mulesoft-anypoint/#21-review-integration-clients-and-connected-app-scopes
#   profile: L1
#   mode: mutating
#   requires: Terraform, mulesoft/anypoint 1.1.1 or compatible, preconfigured provider authority
# Source: https://docs.mulesoft.com/mulesoft-terraform-provider/access-management-resources
# HTH Guide Excerpt: begin scoped-connected-app
# Compose with an authenticated provider configuration. Protect Terraform state:
# the new Connected App secret is returned on creation and retained in state.
terraform {
  required_providers {
    anypoint = {
      source  = "mulesoft/anypoint"
      version = "~> 1.1"
    }
  }
}

variable "organization_id" {
  type        = string
  description = "Approved Anypoint organization or business-group ID."
}

variable "environment_id" {
  type        = string
  description = "Approved environment ID belonging to that organization or group."
}

resource "anypoint_connected_app" "application_inventory" {
  organization_id = var.organization_id
  name            = "Approved environment application inventory"
  grant_types     = ["client_credentials"]
  audience        = "internal"

  scopes = [{
    scope          = "Read Applications"
    context_params = { org = var.organization_id, envId = var.environment_id }
  }]
}
# HTH Guide Excerpt: end scoped-connected-app
