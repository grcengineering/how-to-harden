# HTH Control anthropic-api 2.1: Segment Workspaces by Environment
# Profile: L1 | NIST: AC-4, SC-7 | SOC 2: CC6.6
# https://howtoharden.com/guides/anthropic-api/#21-segment-workspaces-by-environment
# Community provider, available v0.3.0; native API checked 2026-11-05.
# Docs: https://registry.terraform.io/providers/jianyuan/anthropic/0.3.0/docs/resources/workspace
#       https://registry.terraform.io/providers/jianyuan/anthropic/0.3.0/docs/data-sources/workspaces
# Inject ANTHROPIC_API_KEY securely; this provider expects a Console ADMIN key.
# init/validate and mock tests are offline; never apply to test a guide.

# HTH Guide Excerpt: begin workspace-resource-and-readback
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    anthropic = {
      source  = "jianyuan/anthropic"
      version = "0.3.0"
    }
  }
}
provider "anthropic" {
  base_url = "https://api.anthropic.com"
}
variable "workspace_names" {
  type    = set(string)
  default = [] # No resources until you choose the environment/team names.
  validation {
    condition     = alltrue([for n in var.workspace_names : can(regex("^[a-z0-9][a-z0-9-]{2,63}$", n))])
    error_message = "Use reviewed team-environment names."
  }
}
resource "anthropic_workspace" "environment" {
  for_each = var.workspace_names
  name     = each.value
  data_residency = {
    workspace_geo         = "us" # Immutable; choose before creation.
    default_inference_geo = "us"
    allowed_inference_geos = {
      values = ["us"]
    }
  }
  lifecycle {
    prevent_destroy = true # Workspace archive is irreversible; no destroy as rollback.
  }
}
data "anthropic_workspaces" "inventory" {}
output "workspace_inventory" {
  sensitive = true
  value     = data.anthropic_workspaces.inventory.workspaces
}
# HTH Guide Excerpt: end workspace-resource-and-readback
