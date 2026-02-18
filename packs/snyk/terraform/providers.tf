# =============================================================================
# Snyk Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Snyk Terraform provider for organization management.
# See: https://registry.terraform.io/providers/snyk/snyk/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    snyk = {
      source  = "snyk/snyk"
      version = "~> 0.1"
    }
  }
}

provider "snyk" {
  api_token = var.snyk_api_token
}
