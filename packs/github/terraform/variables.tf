# =============================================================================
# HTH GitHub Terraform Variables
# Shared variable declarations for all GitHub hardening controls
# =============================================================================

variable "github_organization" {
  description = "GitHub organization name to apply hardening controls"
  type        = string
}

variable "repository_name" {
  description = "Name of the GitHub repository to harden"
  type        = string
  default     = "how-to-harden"
}

variable "repository_id" {
  description = "GitHub repository ID for branch protection resources"
  type        = string
}

variable "security_team_id" {
  description = "GitHub team ID for the security review team (used in deployment environment reviewers)"
  type        = string
  default     = null
}
