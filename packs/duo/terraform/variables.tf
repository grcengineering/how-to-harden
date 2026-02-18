# =============================================================================
# HTH Duo Security Code Pack - Variables
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
# Cisco ISE Provider Configuration
# -----------------------------------------------------------------------------

variable "ise_url" {
  description = "Cisco ISE base URL (e.g., https://ise.example.com)"
  type        = string
}

variable "ise_username" {
  description = "Cisco ISE admin username for API access"
  type        = string
}

variable "ise_password" {
  description = "Cisco ISE admin password for API access"
  type        = string
  sensitive   = true
}

variable "ise_insecure" {
  description = "Allow insecure TLS connections to ISE (set true only for lab/test)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Duo Admin API Configuration (for null_resource provisioners)
# -----------------------------------------------------------------------------

variable "duo_api_hostname" {
  description = "Duo Admin API hostname (e.g., api-XXXXXXXX.duosecurity.com)"
  type        = string
}

variable "duo_integration_key" {
  description = "Duo Admin API integration key (ikey)"
  type        = string
  sensitive   = true
}

variable "duo_secret_key" {
  description = "Duo Admin API secret key (skey)"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: Admin Account Security
# -----------------------------------------------------------------------------

variable "admin_role_limit_owners" {
  description = "Maximum number of Owner-role admin accounts (recommended: 2)"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Section 2.1: Global Policy
# -----------------------------------------------------------------------------

variable "global_policy_new_user_action" {
  description = "Action for new (unenrolled) users: DENY or ENROLL"
  type        = string
  default     = "DENY"

  validation {
    condition     = contains(["DENY", "ENROLL"], var.global_policy_new_user_action)
    error_message = "New user action must be DENY or ENROLL."
  }
}

# -----------------------------------------------------------------------------
# Section 2.3: Phishing-Resistant MFA (L2)
# -----------------------------------------------------------------------------

variable "verified_push_enabled" {
  description = "Enable Verified Duo Push (number matching) to resist MFA fatigue attacks"
  type        = bool
  default     = true
}

variable "disable_sms_passcodes" {
  description = "Disable SMS passcodes as an authentication method (L2+)"
  type        = bool
  default     = false
}

variable "disable_phone_callback" {
  description = "Disable phone callback as an authentication method (L2+)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 2.4: Authorized Networks (L2)
# -----------------------------------------------------------------------------

variable "authorized_networks_cidrs" {
  description = "List of authorized corporate network CIDRs for network-aware policies"
  type        = list(string)
  default     = []
}

variable "authorized_networks_require_mfa" {
  description = "Require MFA even from authorized networks (recommended: true)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.1: Inactive Account Threshold
# -----------------------------------------------------------------------------

variable "inactive_days_threshold" {
  description = "Number of days of inactivity before an account is flagged (default: 90)"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Section 3.2: Enrollment Security
# -----------------------------------------------------------------------------

variable "enrollment_link_expiry_hours" {
  description = "Hours before enrollment links expire (24-72 recommended)"
  type        = number
  default     = 48

  validation {
    condition     = var.enrollment_link_expiry_hours >= 1 && var.enrollment_link_expiry_hours <= 720
    error_message = "Enrollment link expiry must be between 1 and 720 hours."
  }
}

# -----------------------------------------------------------------------------
# Section 4.1: Trusted Endpoints (L2)
# -----------------------------------------------------------------------------

variable "trusted_endpoints_enabled" {
  description = "Require device trust verification before granting access (L2+, requires Duo Advantage)"
  type        = bool
  default     = false
}

variable "block_untrusted_devices" {
  description = "Block untrusted devices entirely (true) or allow with warning (false)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 5.1: Application Security - ISE Policy Sets
# -----------------------------------------------------------------------------

variable "duo_ise_identity_source_name" {
  description = "Name of the Duo MFA identity source in ISE"
  type        = string
  default     = "Duo-MFA"
}

variable "duo_ise_policy_set_name" {
  description = "Name of the ISE network access policy set for Duo-protected access"
  type        = string
  default     = "Duo-MFA-Protected-Access"
}

# -----------------------------------------------------------------------------
# Section 5.2: Windows Logon / RDP
# -----------------------------------------------------------------------------

variable "rdp_fail_mode" {
  description = "Duo Windows Logon fail mode: CLOSED (more secure) or OPEN (more available)"
  type        = string
  default     = "CLOSED"

  validation {
    condition     = contains(["CLOSED", "OPEN"], var.rdp_fail_mode)
    error_message = "RDP fail mode must be CLOSED or OPEN."
  }
}

variable "rdp_offline_access_enabled" {
  description = "Enable offline access for Windows Logon (allows limited logins when Duo is unreachable)"
  type        = bool
  default     = false
}

variable "rdp_offline_expiry_hours" {
  description = "Hours before offline access expires (24-72 recommended)"
  type        = number
  default     = 48
}

variable "rdp_offline_max_logins" {
  description = "Maximum number of offline logins allowed"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Section 6.1: Logging and SIEM Integration
# -----------------------------------------------------------------------------

variable "siem_integration_enabled" {
  description = "Enable Duo Admin API log export for SIEM integration"
  type        = bool
  default     = true
}

variable "trust_monitor_enabled" {
  description = "Enable Duo Trust Monitor for anomaly detection (requires Advantage/Premier)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 6.3: Session Hijacking Protection (L2)
# -----------------------------------------------------------------------------

variable "session_timeout_minutes" {
  description = "Session timeout in minutes for Duo-protected applications"
  type        = number
  default     = 60
}

variable "reauthentication_for_sensitive_actions" {
  description = "Require re-authentication for sensitive actions (L2+)"
  type        = bool
  default     = false
}
