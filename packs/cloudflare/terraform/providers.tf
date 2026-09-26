# =============================================================================
# Cloudflare Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Every pack in this directory is written against the Cloudflare provider v5
# schema (object-attribute syntax such as `service_mode_v2 = { ... }` and the
# application-side `policies = [...]` binding). Validated with provider
# v5.25.0. Terraform >= 1.5 is required for the `check` blocks in packs 1.6,
# 3.2, 3.5, 4.2 and 4.3.
# See: https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Authenticates from the CLOUDFLARE_API_TOKEN environment variable
provider "cloudflare" {}
