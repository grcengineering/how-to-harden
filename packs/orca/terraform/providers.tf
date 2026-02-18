# =============================================================================
# Orca Security Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Orca Security Terraform provider for platform management.
# See: https://registry.terraform.io/providers/orcasecurity/orcasecurity/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    orcasecurity = {
      source  = "orcasecurity/orcasecurity"
      version = "~> 0.5"
    }
  }
}

provider "orcasecurity" {
  api_endpoint = var.orca_api_endpoint
  api_token    = var.orca_api_token
}
