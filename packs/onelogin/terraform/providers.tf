# =============================================================================
# OneLogin Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the OneLogin Terraform provider for tenant management.
# See: https://registry.terraform.io/providers/onelogin/onelogin/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    onelogin = {
      source  = "onelogin/onelogin"
      version = "~> 0.4"
    }
  }
}

provider "onelogin" {
  client_id     = var.onelogin_client_id
  client_secret = var.onelogin_client_secret
}
