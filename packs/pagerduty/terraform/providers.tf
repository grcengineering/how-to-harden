# =============================================================================
# PagerDuty Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the PagerDuty Terraform provider for account management.
# See: https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    pagerduty = {
      source  = "PagerDuty/pagerduty"
      version = "~> 3.0"
    }
  }
}

provider "pagerduty" {
  token = var.pagerduty_api_token
}
