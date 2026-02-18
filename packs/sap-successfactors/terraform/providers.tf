# =============================================================================
# SAP SuccessFactors Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the SAP BTP Terraform provider for SuccessFactors management.
# See: https://registry.terraform.io/providers/SAP/btp/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.0"
    }
  }
}

provider "btp" {
  globalaccount = var.btp_globalaccount
  cli_server_url = var.btp_cli_server_url
  username       = var.btp_username
  password       = var.btp_password
}
