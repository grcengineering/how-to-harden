# =============================================================================
# HTH Terraform Cloud Control 1.02: Team-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/terraform-cloud/#12-team-based-access-control
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

variable "workspace_ids" {
  description = "Map of workspace names to workspace IDs for access grants"
  type        = map(string)
  default     = {}
}

# HTH Guide Excerpt: begin terraform
# --- Team definitions ---
# Owners team is managed by Terraform Cloud automatically; do not recreate it.

resource "tfe_team" "platform" {
  name         = "platform"
  organization = var.tfc_organization

  organization_access {
    manage_workspaces = true
    manage_policies   = false
    manage_providers  = true
    manage_modules    = true
    manage_vcs_settings = false
  }
}

resource "tfe_team" "developers" {
  name         = "developers"
  organization = var.tfc_organization

  organization_access {
    manage_workspaces   = false
    manage_policies     = false
    manage_providers    = false
    manage_modules      = false
    manage_vcs_settings = false
  }
}

resource "tfe_team" "readonly" {
  name         = "read-only"
  organization = var.tfc_organization

  organization_access {
    manage_workspaces   = false
    manage_policies     = false
    manage_providers    = false
    manage_modules      = false
    manage_vcs_settings = false
  }
}

# --- Workspace-level access grants ---
# Platform team: admin on all workspaces
resource "tfe_team_access" "platform" {
  for_each     = var.workspace_ids
  team_id      = tfe_team.platform.id
  workspace_id = each.value
  access       = "admin"
}

# Developers: plan-only on all workspaces (no apply)
resource "tfe_team_access" "developers" {
  for_each     = var.workspace_ids
  team_id      = tfe_team.developers.id
  workspace_id = each.value
  access       = "plan"
}

# Read-only: read on all workspaces
resource "tfe_team_access" "readonly" {
  for_each     = var.workspace_ids
  team_id      = tfe_team.readonly.id
  workspace_id = each.value
  access       = "read"
}
# HTH Guide Excerpt: end terraform
