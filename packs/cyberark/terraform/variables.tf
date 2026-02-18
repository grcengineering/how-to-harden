# =============================================================================
# CyberArk Hardening Code Pack - Variables
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
# Conjur Provider Configuration
# -----------------------------------------------------------------------------

variable "conjur_appliance_url" {
  description = "URL of the CyberArk Conjur appliance (e.g., https://conjur.company.com)"
  type        = string
}

variable "conjur_account" {
  description = "Conjur account name (organization account identifier)"
  type        = string
}

variable "conjur_login" {
  description = "Conjur login identity (e.g., admin or host/myapp)"
  type        = string
}

variable "conjur_api_key" {
  description = "Conjur API key for authentication"
  type        = string
  sensitive   = true
}

variable "conjur_ssl_cert_path" {
  description = "Path to the Conjur appliance SSL certificate for TLS verification"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# CyberArk PVWA Configuration (for REST API provisioners)
# -----------------------------------------------------------------------------

variable "pvwa_url" {
  description = "CyberArk PVWA base URL (e.g., https://pvwa.company.com)"
  type        = string
}

variable "pvwa_auth_token" {
  description = "CyberArk PVWA API authentication token"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: MFA Configuration
# -----------------------------------------------------------------------------

variable "mfa_radius_server" {
  description = "RADIUS server hostname for MFA integration"
  type        = string
  default     = ""
}

variable "mfa_radius_port" {
  description = "RADIUS server port"
  type        = number
  default     = 1812
}

variable "mfa_radius_timeout" {
  description = "RADIUS authentication timeout in seconds"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Section 1.2: Vault-Level Access Controls
# -----------------------------------------------------------------------------

variable "safes" {
  description = "Map of safes to create with access control settings"
  type = map(object({
    description       = string
    managing_cpm      = string
    retention_versions = number
    retention_days    = number
    olac_enabled      = bool
  }))
  default = {
    "Windows-DomainAdmins" = {
      description       = "Domain Administrator credentials - requires approval"
      managing_cpm      = "PasswordManager"
      retention_versions = 10
      retention_days    = 30
      olac_enabled      = true
    }
    "Linux-Root" = {
      description       = "Linux root credentials"
      managing_cpm      = "PasswordManager"
      retention_versions = 10
      retention_days    = 30
      olac_enabled      = true
    }
    "Application-Secrets" = {
      description       = "Application API keys and secrets"
      managing_cpm      = "PasswordManager"
      retention_versions = 5
      retention_days    = 30
      olac_enabled      = false
    }
  }
}

variable "safe_members" {
  description = "Map of safe member assignments with granular permissions"
  type = map(object({
    safe_name           = string
    member_name         = string
    member_type         = string
    use_accounts        = bool
    retrieve_accounts   = bool
    list_accounts       = bool
    add_accounts        = bool
    update_accounts     = bool
    delete_accounts     = bool
    manage_safe         = bool
    request_auth_level  = number
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 1.3: Break-Glass Procedures
# -----------------------------------------------------------------------------

variable "break_glass_safe_name" {
  description = "Name of the break-glass emergency safe"
  type        = string
  default     = "Emergency-BreakGlass"
}

variable "break_glass_approval_count" {
  description = "Number of approvers required for break-glass access"
  type        = number
  default     = 2
}

variable "break_glass_expiration_hours" {
  description = "Hours before break-glass access expires"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Section 3.1: API Authentication
# -----------------------------------------------------------------------------

variable "api_allowed_ips" {
  description = "List of IP addresses allowed for API authentication"
  type        = list(string)
  default     = []
}

variable "api_rate_limit_max_concurrent" {
  description = "Maximum concurrent API requests"
  type        = number
  default     = 50
}

variable "api_rate_limit_timeout" {
  description = "API request timeout in seconds"
  type        = number
  default     = 120
}

# -----------------------------------------------------------------------------
# Section 3.2: Integration Permissions
# -----------------------------------------------------------------------------

variable "integration_users" {
  description = "Map of integration service accounts with their safe access"
  type = map(object({
    safe_access    = list(string)
    use_accounts   = bool
    retrieve       = bool
    list_accounts  = bool
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 4.1: Session Management
# -----------------------------------------------------------------------------

variable "session_max_duration_minutes" {
  description = "Maximum PSM session duration in minutes (480=8h for L1, 240=4h for L2)"
  type        = number
  default     = 480
}

variable "session_idle_timeout_minutes" {
  description = "PSM session idle timeout in minutes (30 for L1, 15 for L2)"
  type        = number
  default     = 30
}

variable "session_recording_enabled" {
  description = "Enable PSM session recording"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 5.1: Secrets Rotation
# -----------------------------------------------------------------------------

variable "password_rotation_days" {
  description = "Password rotation interval in days (30 for L1, 7 for L2)"
  type        = number
  default     = 30
}

variable "password_min_length" {
  description = "Minimum password length for managed accounts"
  type        = number
  default     = 20
}

variable "password_verification_interval_hours" {
  description = "Password verification interval in hours"
  type        = number
  default     = 24
}

# -----------------------------------------------------------------------------
# Section 6.1: Audit Logging
# -----------------------------------------------------------------------------

variable "siem_server" {
  description = "SIEM server hostname for audit log forwarding"
  type        = string
  default     = ""
}

variable "siem_port" {
  description = "SIEM server port for syslog forwarding"
  type        = number
  default     = 514
}

variable "audit_retention_days" {
  description = "Number of days to retain audit logs"
  type        = number
  default     = 365
}
