# =============================================================================
# Wiz Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Wiz Terraform provider for tenant management.
# See: https://registry.terraform.io/providers/AxtonGrams/wiz/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    wiz = {
      source  = "AxtonGrams/wiz"
      version = "~> 0.1"
    }
  }
}

provider "wiz" {
  wiz_url                = var.wiz_url
  wiz_auth_client_id     = var.wiz_auth_client_id
  wiz_auth_client_secret = var.wiz_auth_client_secret
  wiz_auth_audience      = var.wiz_auth_audience
}
