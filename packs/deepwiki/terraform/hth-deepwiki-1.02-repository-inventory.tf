# HTH Pack Contract: v1
#   control: deepwiki-1.2
#   guide: https://howtoharden.com/guides/deepwiki/#12-review-indexed-repositories-and-additional-branches
#   profile: L2
#   mode: read-only
#   requires: Terraform, DEVIN_TOKEN(scoped service-user credential), deepwiki_org_id
# HTH DeepWiki 1.2: Read connected repositories and indexing flags
# Profile Level: L2 (Walk) | NIST 800-53: AC-6, CM-8
# Sources (provider v0.5.0; fetched 2026-10-29):
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/data-sources/repositories.md
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/index.md
# Data source is read-only. It reports indexing_enabled, NOT indexed branches.
# Use the API pack for the branch inventory. Protect Terraform state and plan
# artifacts: sensitive outputs redact presentation, not stored state contents.
# Run in a separate empty Terraform directory; do not apply unrelated changes.

# HTH Guide Excerpt: begin read-repository-indexing-inventory
terraform {
  required_providers {
    devin = {
      source  = "cognitionai/devin"
      version = "= 0.5.0"
    }
  }
}

provider "devin" {
  # DEVIN_TOKEN is injected by your approved secret manager, never committed.
  api_url = "https://api.devin.ai"
}

variable "deepwiki_org_id" {
  type        = string
  description = "The approved Devin organization to inventory."
  validation {
    condition     = can(regex("^org-[A-Za-z0-9_-]+$", var.deepwiki_org_id))
    error_message = "Supply a Devin organization ID with the org- prefix."
  }
}

data "devin_repositories" "deepwiki_inventory" {
  org_id = var.deepwiki_org_id
}

output "deepwiki_repository_indexing_flags" {
  description = "Review against approvals; not an indexed-branch inventory or a compliance verdict."
  sensitive   = true
  value = [for repository in data.devin_repositories.deepwiki_inventory.repositories : {
    repository_path  = repository.repository_path
    indexing_enabled = repository.indexing_enabled
  }]
}
# HTH Guide Excerpt: end read-repository-indexing-inventory
