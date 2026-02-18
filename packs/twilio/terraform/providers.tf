# =============================================================================
# Twilio Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Twilio Terraform provider for account management.
# See: https://registry.terraform.io/providers/twilio/twilio/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    twilio = {
      source  = "twilio/twilio"
      version = "~> 0.18"
    }
  }
}

provider "twilio" {
  account_sid = var.twilio_account_sid
  auth_token  = var.twilio_auth_token
}
