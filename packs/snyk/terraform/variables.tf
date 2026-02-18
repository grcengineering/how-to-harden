# =============================================================================
# Snyk Hardening Code Pack - Variables
# How to Harden (howtoharden.com)
#
# Profile levels are cumulative: L2 includes L1, L3 includes L1+L2.
# Usage: terraform apply -var="profile_level=1"
# =============================================================================

# -----------------------------------------------------------------------------
# Profile Level
# -----------------------------------------------------------------------------

variable "profile_level" {
  description = "Hardening profile level: 1 = Baseline, 2 = Hardened, 3 = Maximum Security"
  type        = number
  default     = 1

  validation {
    condition     = var.profile_level >= 1 && var.profile_level <= 3
    error_message = "Profile level must be 1, 2, or 3."
  }
}

# -----------------------------------------------------------------------------
# Snyk Provider Configuration
# -----------------------------------------------------------------------------

variable "snyk_api_token" {
  description = "Snyk API token for provider authentication (Settings > General > API Token, or service account token)"
  type        = string
  sensitive   = true
}

variable "snyk_org_id" {
  description = "Snyk organization ID (Settings > General > Organization ID)"
  type        = string
}

variable "snyk_group_id" {
  description = "Snyk group ID for group-level settings (Enterprise only, leave empty to skip)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

variable "sso_enabled" {
  description = "Whether to enforce SSO for the organization (requires Business/Enterprise plan)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Role-Based Access
# -----------------------------------------------------------------------------

variable "restricted_roles" {
  description = "Map of user emails to their assigned Snyk roles (admin, collaborator, custom)"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Section 2.1: Service Account Tokens
# -----------------------------------------------------------------------------

variable "service_accounts" {
  description = "List of service accounts to create with least-privilege roles"
  type = list(object({
    name = string
    role = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 2.2: SCM Integration Security
# -----------------------------------------------------------------------------

variable "scm_integration_type" {
  description = "SCM integration type: github, gitlab, bitbucket-cloud, azure-repos"
  type        = string
  default     = "github"
}

variable "broker_enabled" {
  description = "Whether Snyk Broker is used for private repository scanning (Enterprise)"
  type        = bool
  default     = false
}

variable "broker_token" {
  description = "Snyk Broker token for private repository integration (leave empty if broker_enabled=false)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 3.1: Project Visibility
# -----------------------------------------------------------------------------

variable "default_project_visibility" {
  description = "Default visibility for new projects: org-public or org-private"
  type        = string
  default     = "org-private"

  validation {
    condition     = contains(["org-public", "org-private"], var.default_project_visibility)
    error_message = "Project visibility must be org-public or org-private."
  }
}

# -----------------------------------------------------------------------------
# Section 3.2: Ignore Policy (L2)
# -----------------------------------------------------------------------------

variable "ignore_expiration_days" {
  description = "Default expiration in days for vulnerability ignores (0 = no expiration, not recommended)"
  type        = number
  default     = 90

  validation {
    condition     = var.ignore_expiration_days >= 0 && var.ignore_expiration_days <= 365
    error_message = "Ignore expiration must be between 0 and 365 days."
  }
}

variable "require_ignore_reason" {
  description = "Whether to require a reason when ignoring vulnerabilities (L2+)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logs & Notification Settings
# -----------------------------------------------------------------------------

variable "notification_emails" {
  description = "List of email addresses to receive security notifications"
  type        = list(string)
  default     = []
}

variable "new_issues_notification" {
  description = "Enable notifications for newly discovered vulnerabilities"
  type        = bool
  default     = true
}

variable "weekly_report_enabled" {
  description = "Enable weekly vulnerability summary report"
  type        = bool
  default     = true
}
