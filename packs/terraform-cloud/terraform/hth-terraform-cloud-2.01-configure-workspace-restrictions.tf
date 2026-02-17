# =============================================================================
# HTH Terraform Cloud Control 2.01: Configure Workspace Restrictions
# Profile Level: L1 (Baseline)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/terraform-cloud/#21-configure-workspace-restrictions
# =============================================================================

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62"
    }
  }
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "workspace_name" {
  description = "Name of the workspace to harden"
  type        = string
  default     = "production"
}

variable "vcs_repo_identifier" {
  description = "VCS repository identifier (e.g., org/repo)"
  type        = string
  default     = ""
}

variable "vcs_oauth_token_id" {
  description = "OAuth token ID for VCS provider connection"
  type        = string
  default     = ""
}

# HTH Guide Excerpt: begin terraform
resource "tfe_workspace" "hardened" {
  name                  = var.workspace_name
  organization          = var.tfc_organization
  execution_mode        = "remote"
  auto_apply            = false
  speculative_enabled   = true
  file_triggers_enabled = true
  queue_all_runs        = false
  assessments_enabled   = true

  # Require VCS-driven runs only -- block CLI/API applies in production
  dynamic "vcs_repo" {
    for_each = var.vcs_repo_identifier != "" ? [1] : []
    content {
      identifier     = var.vcs_repo_identifier
      oauth_token_id = var.vcs_oauth_token_id
      branch         = "main"
    }
  }
}
# HTH Guide Excerpt: end terraform
