# =============================================================================
# Docker Hub Hardening Code Pack - Variables
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
# Docker Provider Configuration
# -----------------------------------------------------------------------------

variable "docker_host" {
  description = "Docker daemon host URL (e.g., unix:///var/run/docker.sock or tcp://localhost:2376)"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "dockerhub_organization" {
  description = "Docker Hub organization name"
  type        = string
}

variable "dockerhub_username" {
  description = "Docker Hub username for API authentication"
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub personal access token for API authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: MFA and SSO
# -----------------------------------------------------------------------------

variable "sso_idp_metadata_url" {
  description = "SAML SSO identity provider metadata URL (Business plan required)"
  type        = string
  default     = ""
}

variable "enforce_sso" {
  description = "Whether to enforce SSO for all organization members (Business plan)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 1.2: Access Tokens
# -----------------------------------------------------------------------------

variable "ci_cd_token_description" {
  description = "Description for the CI/CD read-only access token"
  type        = string
  default     = "CI/CD pipeline - read-only"
}

variable "build_token_description" {
  description = "Description for the build/push access token"
  type        = string
  default     = "Build pipeline - read/write"
}

variable "ci_cd_token_scopes" {
  description = "Permission scopes for CI/CD token (read-only pulls)"
  type        = list(string)
  default     = ["repo:read"]
}

variable "build_token_scopes" {
  description = "Permission scopes for build token (read/write for specific repos)"
  type        = list(string)
  default     = ["repo:read", "repo:write"]
}

# -----------------------------------------------------------------------------
# Section 2.2: Image Signing (L2+)
# -----------------------------------------------------------------------------

variable "enable_content_trust" {
  description = "Enable Docker Content Trust for image signing (L2+)"
  type        = bool
  default     = false
}

variable "signing_key_passphrase" {
  description = "Passphrase for the Docker Content Trust signing key (L2+)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 3.1: Repository Security
# -----------------------------------------------------------------------------

variable "repositories" {
  description = "Map of repository names to their configuration (visibility, description)"
  type = map(object({
    description = string
    visibility  = optional(string, "private")
  }))
  default = {}
}

variable "team_repository_permissions" {
  description = "Map of team names to their repository access permissions"
  type = map(object({
    permission = string
    members    = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_log_export_enabled" {
  description = "Whether to export Docker Hub audit logs to external SIEM (Business plan)"
  type        = bool
  default     = false
}

variable "siem_webhook_url" {
  description = "Webhook URL for forwarding audit log events to SIEM"
  type        = string
  default     = ""
  sensitive   = true
}
