# =============================================================================
# CyberArk Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the CyberArk Conjur Terraform provider for secrets management
# and security configuration.
# See: https://registry.terraform.io/providers/cyberark/conjur/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.6"
    }
  }
}

provider "conjur" {
  appliance_url = var.conjur_appliance_url
  account       = var.conjur_account
  login         = var.conjur_login
  api_key       = var.conjur_api_key
  ssl_cert_path = var.conjur_ssl_cert_path
}
