# =============================================================================
# 1Password Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the 1Password Terraform provider for Business/Enterprise management.
# See: https://registry.terraform.io/providers/1Password/onepassword/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
  }
}

provider "onepassword" {
  service_account_token = var.op_service_account_token
  url                   = var.op_connect_url
}
