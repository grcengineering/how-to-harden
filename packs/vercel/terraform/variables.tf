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

variable "project_name" {
  description = "Current name of the EXISTING project identified by project_id. hth-vercel-2.01 imports that project (it never creates one) and stops if the name and id do not match. The project's Git connection, framework and build settings are left as they are."
  type        = string
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
# Section 2.4: Private Production Deployments (Advanced Deployment Protection)
# -----------------------------------------------------------------------------

variable "private_production_deployments_enabled" {
  description = "Enable All-Deployments scope (includes production domains) — Enterprise or Pro Advanced DP add-on (L2+)"
  type        = bool
  default     = false
}

variable "production_only_trusted_ips_enabled" {
  description = "Restrict production deployments to trusted IPs while leaving preview publicly accessible (Enterprise only, L3)"
  type        = bool
  default     = false
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
  description = "Manage the project firewall with this pack and turn it on. Setting this, blocked_ip_addresses or rate_limit_rules creates vercel_firewall_config, which REPLACES the whole existing firewall configuration (see firewall_replace_existing_config)."
  type        = bool
  default     = false
}

variable "firewall_replace_existing_config" {
  description = "Acknowledge that vercel_firewall_config PUTs the whole firewall configuration: custom rules and IP blocks made in the dashboard or by the 3.3/9.1 API packs are replaced unless declared here. Required when the firewall is managed."
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

variable "firewall_hostname" {
  description = "Hostname the IP-block rules apply to (ip_rules.rule.hostname is required when blocked_ip_addresses is set)"
  type        = string
  default     = ""
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

variable "secure_compute_cidr" {
  description = "CIDR range for the Secure Compute network (required by vercel_network)"
  type        = string
  default     = "10.0.0.0/16"
}

# -----------------------------------------------------------------------------
# Section 4.2: Attack Challenge Mode
# -----------------------------------------------------------------------------

variable "attack_challenge_mode_enabled" {
  description = "Turn Attack Challenge Mode on (during an attack). False leaves the mode unmanaged; switching true -> false turns it off."
  type        = bool
  default     = false
}

variable "attack_mode_active_until" {
  description = "Unix time in MILLISECONDS until which Attack Challenge Mode stays active (required by vercel_attack_challenge_mode; Vercel turns the mode off when it passes)"
  type        = number
  default     = 0
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

variable "retention_preview" {
  description = "Retention for preview deployments (L2+): one of 1d, 1w, 1m, 2m, 3m, 6m, 1y"
  type        = string
  default     = "1m"

  validation {
    condition     = contains(["1d", "1w", "1m", "2m", "3m", "6m", "1y"], var.retention_preview)
    error_message = "Use one of 1d, 1w, 1m, 2m, 3m, 6m, 1y."
  }
}

variable "retention_production" {
  description = "Retention for production deployments (L2+): one of 1d, 1w, 1m, 2m, 3m, 6m, 1y"
  type        = string
  default     = "1y"

  validation {
    condition     = contains(["1d", "1w", "1m", "2m", "3m", "6m", "1y"], var.retention_production)
    error_message = "Use one of 1d, 1w, 1m, 2m, 3m, 6m, 1y."
  }
}

variable "retention_canceled" {
  description = "Retention for canceled deployments (L2+): one of 1d, 1w, 1m, 2m, 3m, 6m, 1y"
  type        = string
  default     = "1w"

  validation {
    condition     = contains(["1d", "1w", "1m", "2m", "3m", "6m", "1y"], var.retention_canceled)
    error_message = "Use one of 1d, 1w, 1m, 2m, 3m, 6m, 1y."
  }
}

variable "retention_errored" {
  description = "Retention for errored deployments (L2+): one of 1d, 1w, 1m, 2m, 3m, 6m, 1y"
  type        = string
  default     = "1w"

  validation {
    condition     = contains(["1d", "1w", "1m", "2m", "3m", "6m", "1y"], var.retention_errored)
    error_message = "Use one of 1d, 1w, 1m, 2m, 3m, 6m, 1y."
  }
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

# -----------------------------------------------------------------------------
# Section 10.4: Container Registry Public Access
# -----------------------------------------------------------------------------

variable "vcr_repositories" {
  description = "Vercel Container Registry repository names in project_id to manage as PRIVATE. Import existing ones first: terraform import 'vercel_vcr_repository.private[\"<name>\"]' <team_id>/<project_id>/<name>"
  type        = set(string)
  default     = []
}
