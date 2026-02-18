# =============================================================================
# Vercel Hardening Code Pack - Variables
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
# Vercel Provider Configuration
# -----------------------------------------------------------------------------

variable "vercel_api_token" {
  description = "Vercel API token for provider authentication"
  type        = string
  sensitive   = true
}

variable "vercel_team_id" {
  description = "Vercel team ID (found in Team Settings > General)"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA (Enterprise)
# -----------------------------------------------------------------------------

variable "saml_enforced" {
  description = "Whether SAML SSO enforcement is enabled (Enterprise only)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Team Access Controls
# -----------------------------------------------------------------------------

variable "team_members" {
  description = "Map of team members to their roles (OWNER, MEMBER, DEVELOPER, VIEWER)"
  type = map(object({
    email = string
    role  = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.1: Secure Deployments
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "Vercel project ID to apply hardening controls"
  type        = string
}

variable "production_branch" {
  description = "Git branch used for production deployments"
  type        = string
  default     = "main"
}

variable "git_repository" {
  description = "Git repository in owner/repo format (e.g., org/my-app)"
  type        = string
  default     = ""
}

variable "git_provider" {
  description = "Git provider type: github, gitlab, or bitbucket"
  type        = string
  default     = "github"
}

variable "preview_password" {
  description = "Password for protecting preview deployments (L2+)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 2.2: Git Integration Security
# -----------------------------------------------------------------------------

variable "git_fork_protection_enabled" {
  description = "Whether to enable Git fork protection to prevent unauthorized deployments"
  type        = bool
  default     = true
}

variable "require_verified_commits" {
  description = "Whether to require verified (signed) commits for deployments (L2+)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 3.1: Environment Variables
# -----------------------------------------------------------------------------

variable "environment_variables" {
  description = "Map of environment variables to configure with security best practices"
  type = map(object({
    value     = string
    target    = set(string)
    sensitive = bool
  }))
  default   = {}
  sensitive = true
}

# -----------------------------------------------------------------------------
# Section 3.2: Access Token Security
# -----------------------------------------------------------------------------

variable "trusted_ip_addresses" {
  description = "List of trusted IP CIDR blocks for IP allowlisting (L2+)"
  type = list(object({
    value = string
    note  = optional(string, "")
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Log & Monitoring
# -----------------------------------------------------------------------------

variable "log_drain_endpoint" {
  description = "HTTPS endpoint URL for forwarding deployment and runtime logs"
  type        = string
  default     = ""
}

variable "log_drain_secret" {
  description = "Shared secret for verifying log drain webhook authenticity"
  type        = string
  default     = ""
  sensitive   = true
}

variable "log_drain_sources" {
  description = "Log sources to forward: static, edge, external, build, lambda, firewall"
  type        = set(string)
  default     = ["static", "edge", "external", "build", "lambda"]
}

variable "log_drain_environments" {
  description = "Environments to collect logs from: production, preview, development"
  type        = set(string)
  default     = ["production", "preview"]
}

# -----------------------------------------------------------------------------
# Section 4.1: Firewall (L2+)
# -----------------------------------------------------------------------------

variable "firewall_enabled" {
  description = "Whether to enable the Vercel Web Application Firewall (L2+)"
  type        = bool
  default     = false
}
