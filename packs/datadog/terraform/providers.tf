# =============================================================================
# Datadog Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Datadog Terraform provider for organization management.
# See: https://registry.terraform.io/providers/DataDog/datadog/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = "~> 3.0"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}
