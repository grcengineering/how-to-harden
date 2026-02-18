# =============================================================================
# Fivetran Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Fivetran Terraform provider for account management.
# See: https://registry.terraform.io/providers/fivetran/fivetran/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    fivetran = {
      source  = "fivetran/fivetran"
      version = "~> 1.0"
    }
  }
}

provider "fivetran" {
  api_key    = var.fivetran_api_key
  api_secret = var.fivetran_api_secret
}
