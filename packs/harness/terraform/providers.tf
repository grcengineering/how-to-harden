# =============================================================================
# Harness Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Harness Terraform provider for platform management.
# See: https://registry.terraform.io/providers/harness/harness/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.30"
    }
  }
}

provider "harness" {
  endpoint         = var.harness_endpoint
  account_id       = var.harness_account_id
  platform_api_key = var.harness_platform_api_key
}
