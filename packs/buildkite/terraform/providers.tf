# =============================================================================
# Buildkite Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Buildkite Terraform provider for organization management.
# See: https://registry.terraform.io/providers/buildkite/buildkite/latest/docs
# =============================================================================

terraform {
  # >= 1.5 for `check` blocks (packs 3.1, 3.5, 3.10, 4.2) on top of the resource
  # preconditions introduced in 1.4. Pack 3.1 no longer uses a `terraform_data`
  # rotation keeper — rotation there is a two-apply add-then-remove, see its
  # TRAP 5. Individual packs raise this floor further: 3.5 needs >= 1.11 for
  # write-only arguments (`value_wo`), so raise it here before adopting that one.
  required_version = ">= 1.5"
  required_providers {
    buildkite = {
      source  = "buildkite/buildkite"
      version = "~> 1.0"
    }
  }
}

provider "buildkite" {
  organization = var.buildkite_organization
  api_token    = var.buildkite_api_token
}
