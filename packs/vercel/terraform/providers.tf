# =============================================================================
# Vercel Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Vercel Terraform provider for team management.
# See: https://registry.terraform.io/providers/vercel/vercel/latest/docs
#
# Terraform >= 1.6: hth-vercel-2.01 adopts the existing project with an
# `import` block whose id is built from variables (allowed from 1.6).
# Provider ~> 5.17: the 2.x line lacks vercel_network.cidr,
# vercel_project_deployment_retention and vercel_vcr_repository, and rejects
# the SAML schema used by hth-vercel-1.01.
# =============================================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 5.17"
    }
  }
}

provider "vercel" {
  api_token = var.vercel_api_token
  team      = var.vercel_team_id
}
