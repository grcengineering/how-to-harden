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
# Section 1.1: Enforce SSO with SAML
# -----------------------------------------------------------------------------

variable "saml_enforced" {
  description = "Whether SAML SSO enforcement is enabled (Enterprise only)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.3: Enforce Least-Privilege RBAC
# -----------------------------------------------------------------------------

variable "team_members" {
  description = "Map of team members to their roles (OWNER, MEMBER, DEVELOPER, SECURITY, BILLING, VIEWER)"
  type = map(object({
    email = string
    role  = string
  }))
  default = {}
}

variable "access_groups" {
  description = "Map of Access Group names (Enterprise, L2+)"
  type        = map(object({}))
  default     = {}
}

variable "access_group_projects" {
  description = "Map of Access Group project assignments (Enterprise, L2+)"
  type = map(object({
    group_name = string
    project_id = string
    role       = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.1: Configure Deployment Protection
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

variable "trusted_ip_addresses" {
  description = "List of trusted IP CIDR blocks for IP allowlisting (L3)"
  type = list(object({
    value = string
    note  = optional(string, "")
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 2.2: Harden Git Integration
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
# Section 3.1: Enable WAF with Managed Rulesets
# -----------------------------------------------------------------------------

variable "firewall_enabled" {
  description = "Whether to enable the Vercel Web Application Firewall"
  type        = bool
  default     = false
}

variable "waf_owasp_action" {
  description = "OWASP ruleset action: log (monitor), deny (block), or challenge"
  type        = string
  default     = "log"

  validation {
    condition     = contains(["log", "deny", "challenge"], var.waf_owasp_action)
    error_message = "WAF action must be log, deny, or challenge."
  }
}

# -----------------------------------------------------------------------------
# Section 3.2: IP Blocking and Rate Limiting
# -----------------------------------------------------------------------------

variable "blocked_ip_addresses" {
  description = "List of IP addresses/ranges to block at the firewall"
  type = list(object({
    value = string
    note  = optional(string, "")
  }))
  default = []
}

variable "rate_limit_rules" {
  description = "Rate limiting rules for sensitive endpoints (L2+)"
  type = list(object({
    name             = string
    path             = string
    limit            = number
    window           = number
    follow_up_action = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 4.1: Secure Compute (L3)
# -----------------------------------------------------------------------------

variable "secure_compute_enabled" {
  description = "Whether to enable Secure Compute (Enterprise, L3)"
  type        = bool
  default     = false
}

variable "secure_compute_name" {
  description = "Name for the Secure Compute network"
  type        = string
  default     = "hth-secure-network"
}

variable "secure_compute_region" {
  description = "AWS region for Secure Compute (e.g., us-east-1)"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Section 4.2: Attack Challenge Mode
# -----------------------------------------------------------------------------

variable "attack_challenge_mode_enabled" {
  description = "Whether Attack Challenge Mode is active (enable during attacks)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 6.1: Environment Variable Security
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
# Section 6.2: Deployment Retention Policy
# -----------------------------------------------------------------------------

variable "deployments_to_keep" {
  description = "Number of deployments to keep (L2+)"
  type        = number
  default     = 10
}

variable "deployment_expiration_days" {
  description = "Days before preview deployments expire (L2+)"
  type        = number
  default     = 30
}

variable "deployment_expiration_days_canceled" {
  description = "Days before canceled deployments expire (L2+)"
  type        = number
  default     = 7
}

variable "deployment_expiration_days_errored" {
  description = "Days before errored deployments expire (L2+)"
  type        = number
  default     = 7
}

variable "deployment_expiration_days_production" {
  description = "Days before production deployments expire (L2+)"
  type        = number
  default     = 365
}

# -----------------------------------------------------------------------------
# Section 8.1: Log Drains for SIEM
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
