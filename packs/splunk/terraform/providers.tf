# =============================================================================
# Splunk Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Splunk Terraform provider for instance management.
# See: https://registry.terraform.io/providers/splunk/splunk/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    splunk = {
      source  = "splunk/splunk"
      version = "~> 1.4"
    }
  }
}

provider "splunk" {
  url                  = var.splunk_url
  username             = var.splunk_username
  password             = var.splunk_password
  auth_token           = var.splunk_auth_token
  insecure_skip_verify = var.splunk_insecure_skip_verify
}
