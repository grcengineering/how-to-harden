# =============================================================================
# CrowdStrike Falcon Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the CrowdStrike Terraform provider for Falcon console management.
# See: https://registry.terraform.io/providers/CrowdStrike/crowdstrike/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    crowdstrike = {
      source  = "crowdstrike/crowdstrike"
      version = "~> 0.5"
    }
  }
}

provider "crowdstrike" {
  client_id     = var.crowdstrike_client_id
  client_secret = var.crowdstrike_client_secret
  cloud         = var.crowdstrike_cloud
}
