# =============================================================================
# JFrog Hardening Code Pack - Variables
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
# JFrog Provider Configuration
# -----------------------------------------------------------------------------

variable "artifactory_url" {
  description = "JFrog Artifactory base URL (e.g., https://mycompany.jfrog.io/artifactory)"
  type        = string
}

variable "artifactory_access_token" {
  description = "JFrog access token for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

variable "saml_idp_url" {
  description = "SAML Identity Provider login URL for SSO configuration"
  type        = string
  default     = ""
}

variable "saml_idp_certificate" {
  description = "SAML Identity Provider X.509 certificate (PEM format)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "saml_service_provider_id" {
  description = "SAML Service Provider entity ID (typically the Artifactory URL)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: Permission Targets
# -----------------------------------------------------------------------------

variable "release_repo_key" {
  description = "Repository key for the production release repository"
  type        = string
  default     = "libs-release-local"
}

variable "snapshot_repo_key" {
  description = "Repository key for the snapshot/build repository"
  type        = string
  default     = "libs-snapshot-local"
}

variable "release_readers_group" {
  description = "Group name for users with read access to release repositories"
  type        = string
  default     = "developers"
}

variable "release_writers_group" {
  description = "Group name for users with deploy access to release repositories"
  type        = string
  default     = "release-managers"
}

variable "ci_cd_group" {
  description = "Group name for CI/CD service accounts with build upload access"
  type        = string
  default     = "ci-cd-accounts"
}

# -----------------------------------------------------------------------------
# Section 1.3: API Key and Token Security
# -----------------------------------------------------------------------------

variable "token_expiry_seconds" {
  description = "Default token expiry in seconds (90 days = 7776000)"
  type        = number
  default     = 7776000
}

# -----------------------------------------------------------------------------
# Section 2.1: Repository Layout Security
# -----------------------------------------------------------------------------

variable "local_repo_keys" {
  description = "List of local repository keys to harden"
  type        = list(string)
  default     = ["libs-release-local", "libs-snapshot-local"]
}

# -----------------------------------------------------------------------------
# Section 2.2: Remote Repository Security
# -----------------------------------------------------------------------------

variable "remote_repo_key" {
  description = "Key for the remote (proxy) repository to harden"
  type        = string
  default     = "maven-remote"
}

variable "remote_repo_url" {
  description = "Upstream URL for the remote repository"
  type        = string
  default     = "https://repo1.maven.org/maven2"
}

variable "blocked_remote_extensions" {
  description = "File extensions to exclude from remote repository proxying"
  type        = string
  default     = "**/*.exe,**/*.dll,**/*.msi"
}

# -----------------------------------------------------------------------------
# Section 2.3: Dependency Confusion Prevention
# -----------------------------------------------------------------------------

variable "virtual_repo_key" {
  description = "Key for the virtual repository used for dependency resolution"
  type        = string
  default     = "libs-virtual"
}

variable "internal_repo_keys" {
  description = "List of internal repository keys (resolved first to prevent dependency confusion)"
  type        = list(string)
  default     = ["libs-release-local", "libs-snapshot-local"]
}

variable "external_repo_keys" {
  description = "List of external/remote repository keys (resolved second)"
  type        = list(string)
  default     = ["maven-remote"]
}

# -----------------------------------------------------------------------------
# Section 3.1: Artifact Signing (L2+)
# -----------------------------------------------------------------------------

variable "gpg_public_key" {
  description = "GPG public key for artifact signature verification (ASCII-armored, L2+)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 4.1: Xray Security Scanning
# -----------------------------------------------------------------------------

variable "xray_watch_repos" {
  description = "List of repository keys to monitor with Xray watches"
  type        = list(string)
  default     = ["libs-release-local"]
}

variable "xray_block_critical" {
  description = "Block download of artifacts with critical vulnerabilities"
  type        = bool
  default     = true
}

variable "xray_block_high" {
  description = "Block download of artifacts with high vulnerabilities (L2+)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_webhook_url" {
  description = "Webhook URL for forwarding audit events to SIEM (leave empty to skip)"
  type        = string
  default     = ""
}
