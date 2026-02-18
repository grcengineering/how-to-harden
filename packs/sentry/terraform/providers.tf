# =============================================================================
# Sentry Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Sentry Terraform provider for organization management.
# See: https://registry.terraform.io/providers/jianyuan/sentry/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    sentry = {
      source  = "jianyuan/sentry"
      version = "~> 0.12"
    }
  }
}

provider "sentry" {
  token    = var.sentry_token
  base_url = var.sentry_base_url
}
