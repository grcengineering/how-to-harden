# =============================================================================
# HTH GitHub Terraform Variables
# Shared variable declarations for all GitHub hardening controls
# =============================================================================

variable "github_organization" {
  description = "GitHub organization name to apply hardening controls"
  type        = string
}

variable "repository_name" {
  description = "Name of an EXISTING GitHub repository to harden (repository packs import it; they never create one)"
  type        = string
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

variable "billing_email" {
  description = "Organization billing email address (required by github_organization_settings; never the org login)"
  type        = string
  default     = null
}

variable "enterprise_slug" {
  description = "GitHub Enterprise Cloud enterprise slug (enterprise-level controls such as the IP allow list)"
  type        = string
  default     = null
}

variable "corporate_cidr" {
  description = "Corporate egress IP address or CIDR range to allow (enterprise IP allow list)"
  type        = string
  default     = null
}

variable "required_workflows_repository_id" {
  description = "Numeric ID of the repository that holds the organization's required workflow files (usually the .github repository)"
  type        = number
  default     = null
}

variable "security_reviewer_permissions" {
  description = "Fine-grained permission names for the Security Reviewer custom repository role (from GET /orgs/{org}/repository-fine-grained-permissions)"
  type        = set(string)
  default     = []
}
