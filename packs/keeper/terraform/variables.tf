# =============================================================================
# Keeper Security Hardening Code Pack - Variables
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
# Keeper Provider Configuration
# -----------------------------------------------------------------------------

variable "keeper_credential" {
  description = "Keeper Secrets Manager credential (Base64-encoded one-time access token or config JSON)"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: Protect Administrator Accounts
# -----------------------------------------------------------------------------

variable "admin_usernames" {
  description = "List of Keeper admin account email addresses (minimum 2 for redundancy)"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.admin_usernames) == 0 || length(var.admin_usernames) >= 2
    error_message = "At least two admin accounts are required for redundancy (or leave empty to skip)."
  }
}

variable "break_glass_account_email" {
  description = "Email address for the break-glass admin account"
  type        = string
  default     = ""
}

variable "break_glass_folder_uid" {
  description = "Keeper shared folder UID for storing break-glass admin credentials"
  type        = string
  default     = ""
}

variable "break_glass_initial_password" {
  description = "Initial password for the break-glass admin record (change immediately after creation)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Shared Folder for Security Configuration Records
# -----------------------------------------------------------------------------

variable "security_config_folder_uid" {
  description = "Keeper shared folder UID for storing security configuration audit records"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: IP Address Allowlisting for Admins (L2)
# -----------------------------------------------------------------------------

variable "admin_allowed_ips" {
  description = "List of IP addresses or CIDRs allowed for admin access (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 1.3: Administrative Event Alerts
# -----------------------------------------------------------------------------

variable "siem_endpoint" {
  description = "SIEM integration endpoint URL for event streaming (Splunk, Sentinel, etc.)"
  type        = string
  default     = ""
}

variable "alert_recipients" {
  description = "Email addresses for administrative event alert notifications"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.1: Master Password Requirements
# -----------------------------------------------------------------------------

variable "master_password_min_length" {
  description = "Minimum master password length (16 for L1, 20 for L2+)"
  type        = number
  default     = 16
}

variable "master_password_require_upper" {
  description = "Require uppercase letters in master password"
  type        = bool
  default     = true
}

variable "master_password_require_lower" {
  description = "Require lowercase letters in master password"
  type        = bool
  default     = true
}

variable "master_password_require_digits" {
  description = "Require digits in master password"
  type        = bool
  default     = true
}

variable "master_password_require_special" {
  description = "Require special characters in master password"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

variable "tfa_required" {
  description = "Require 2FA for all users"
  type        = bool
  default     = true
}

variable "tfa_allowed_methods" {
  description = "Allowed 2FA methods: totp, fido2, duo, rsa"
  type        = list(string)
  default     = ["totp", "fido2"]
}

variable "tfa_disable_sms" {
  description = "Disable SMS as a 2FA method (vulnerable to SIM swap)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.3: Sharing and Export Restrictions
# -----------------------------------------------------------------------------

variable "restrict_sharing_to_org" {
  description = "Restrict sharing to within the organization only (L2+)"
  type        = bool
  default     = false
}

variable "disable_export" {
  description = "Disable vault export for users (L2+)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 2.4: Browser Extension Restrictions (L2)
# -----------------------------------------------------------------------------

variable "approved_browser_extensions" {
  description = "List of approved browser extension IDs beyond Keeper (format: 'Chrome: <id> (Name)')"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Biometric Authentication
# -----------------------------------------------------------------------------

variable "biometric_timeout_minutes" {
  description = "Biometric authentication timeout in minutes before requiring master password"
  type        = number
  default     = 15
}

# -----------------------------------------------------------------------------
# Section 4.1: SAML SSO Configuration (L2)
# -----------------------------------------------------------------------------

variable "sso_entity_id" {
  description = "SAML SSO Entity ID from your identity provider"
  type        = string
  default     = ""
}

variable "sso_url" {
  description = "SAML SSO URL from your identity provider"
  type        = string
  default     = ""
}

variable "sso_certificate" {
  description = "SAML SSO X.509 certificate (PEM format) from your identity provider"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 4.2: Just-in-Time Provisioning (L2)
# -----------------------------------------------------------------------------

variable "scim_endpoint" {
  description = "SCIM endpoint URL for automated user lifecycle management"
  type        = string
  default     = ""
}

variable "jit_default_role" {
  description = "Default Keeper role assigned to JIT-provisioned users"
  type        = string
  default     = "Default User"
}

# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs"
  type        = number
  default     = 365
}

# -----------------------------------------------------------------------------
# Section 5.3: BreachWatch
# -----------------------------------------------------------------------------

variable "breachwatch_enabled" {
  description = "Enable BreachWatch for compromised credential detection"
  type        = bool
  default     = true
}
