# =============================================================================
# Vercel Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Vercel Terraform provider for team management.
# See: https://registry.terraform.io/providers/vercel/vercel/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
  }
}

provider "vercel" {
  api_token = var.vercel_api_token
  team      = var.vercel_team_id
}
