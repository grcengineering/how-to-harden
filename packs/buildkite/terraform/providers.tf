# =============================================================================
# Buildkite Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Buildkite Terraform provider for organization management.
# See: https://registry.terraform.io/providers/buildkite/buildkite/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
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
