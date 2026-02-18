# =============================================================================
# SendGrid Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the SendGrid Terraform provider for account management.
# See: https://registry.terraform.io/providers/kenzo0107/sendgrid/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    sendgrid = {
      source  = "kenzo0107/sendgrid"
      version = "~> 1.0"
    }
  }
}

provider "sendgrid" {
  api_key = var.sendgrid_api_key
}
