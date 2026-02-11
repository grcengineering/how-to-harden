# =============================================================================
# Okta Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Okta Terraform provider for tenant management.
# See: https://registry.terraform.io/providers/okta/okta/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 4.0"
    }
  }
}

provider "okta" {
  org_name  = var.okta_org_name
  base_url  = var.okta_base_url
  api_token = var.okta_api_token
}
