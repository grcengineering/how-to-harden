# =============================================================================
# New Relic Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the New Relic Terraform provider for account management.
# See: https://registry.terraform.io/providers/newrelic/newrelic/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.0"
    }
  }
}

provider "newrelic" {
  account_id = var.newrelic_account_id
  api_key    = var.newrelic_api_key
  region     = var.newrelic_region
}
