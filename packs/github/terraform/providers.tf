# =============================================================================
# HTH GitHub Terraform Provider Configuration
# Shared provider requirements for all GitHub hardening controls.
# The provider moved from hashicorp/github to integrations/github; an
# unpinned configuration resolves the deprecated namespace, so pin it here.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

# Every pack targets the organization named in var.github_organization.
# Without an explicit owner the provider falls back to the token owner's
# personal namespace.
provider "github" {
  owner = var.github_organization
}
