# =============================================================================
# OneLogin Hardening Code Pack - Variables
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
# OneLogin Provider Configuration
# -----------------------------------------------------------------------------

variable "onelogin_client_id" {
  description = "OneLogin API client ID (generate at Developers > API Credentials)"
  type        = string
}

variable "onelogin_client_secret" {
  description = "OneLogin API client secret"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: Password Policy
# -----------------------------------------------------------------------------

variable "password_min_length" {
  description = "Minimum password length (12 for L1, 14+ for L2/L3)"
  type        = number
  default     = 12
}

variable "password_max_failed_attempts" {
  description = "Maximum failed login attempts before lockout"
  type        = number
  default     = 5
}

variable "password_lockout_duration_minutes" {
  description = "Account lockout duration in minutes after failed attempts"
  type        = number
  default     = 30
}

variable "password_history_count" {
  description = "Number of previous passwords to prevent reuse"
  type        = number
  default     = 10
}

variable "password_expiry_days" {
  description = "Password expiration in days (90 for L1, 60 for L2/L3; 0 to disable)"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Section 1.2: Session Controls
# -----------------------------------------------------------------------------

variable "session_timeout_minutes" {
  description = "Session timeout in minutes (480=8h for L1, 240=4h for L2)"
  type        = number
  default     = 480
}

variable "idle_timeout_minutes" {
  description = "Idle session timeout in minutes (15 for L1, 5 for L2)"
  type        = number
  default     = 15
}

# -----------------------------------------------------------------------------
# Section 2.1: MFA Enforcement
# -----------------------------------------------------------------------------

variable "mfa_policy_name" {
  description = "Name for the MFA enforcement user policy"
  type        = string
  default     = "HTH MFA Required Policy"
}

# -----------------------------------------------------------------------------
# Section 2.2: SmartFactor Authentication (L2)
# -----------------------------------------------------------------------------

variable "smartfactor_policy_name" {
  description = "Name for the SmartFactor adaptive MFA policy (L2+)"
  type        = string
  default     = "HTH SmartFactor Policy"
}

# -----------------------------------------------------------------------------
# Section 2.3: Phishing-Resistant MFA for Admins (L2)
# -----------------------------------------------------------------------------

variable "admin_user_ids" {
  description = "List of OneLogin user IDs for administrators requiring phishing-resistant MFA"
  type        = list(number)
  default     = []
}

variable "admin_mfa_policy_name" {
  description = "Name for the admin WebAuthn-only MFA policy (L2+)"
  type        = string
  default     = "HTH Admin WebAuthn Policy"
}

# -----------------------------------------------------------------------------
# Section 3.1: Delegated Administration
# -----------------------------------------------------------------------------

variable "create_custom_roles" {
  description = "Whether to create custom delegated admin roles"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.2: IP Address Allowlisting (L2)
# -----------------------------------------------------------------------------

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses/CIDRs for login restriction (L2+)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

variable "siem_webhook_url" {
  description = "Webhook URL for SIEM log export (leave empty to skip)"
  type        = string
  default     = ""
}
