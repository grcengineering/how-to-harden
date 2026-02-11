# =============================================================================
# Okta Hardening Code Pack - Variables
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
# Okta Provider Configuration
# -----------------------------------------------------------------------------

variable "okta_org_name" {
  description = "Okta organization name (the subdomain in yourorg.okta.com)"
  type        = string
}

variable "okta_base_url" {
  description = "Okta base URL (okta.com, oktapreview.com, or okta-emea.com)"
  type        = string
  default     = "okta.com"
}

variable "okta_api_token" {
  description = "Okta API token (SSWS) for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

variable "admin_group_id" {
  description = "Okta group ID for administrators requiring phishing-resistant MFA"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.10: Password Policy & Recovery
# -----------------------------------------------------------------------------

variable "everyone_group_id" {
  description = "Okta group ID for the Everyone group (used in password policy)"
  type        = string
  default     = ""
}

variable "password_min_length" {
  description = "Minimum password length (12 for L1, 15 for L2/L3 per DISA STIG)"
  type        = number
  default     = 15
}

variable "password_max_age_days" {
  description = "Maximum password age in days (90 for L1, 60 for L2/L3 per DISA STIG)"
  type        = number
  default     = 60
}

variable "password_history_count" {
  description = "Number of previous passwords to remember (5 per DISA STIG)"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Section 1.11: End-User Notifications
# -----------------------------------------------------------------------------

variable "okta_domain" {
  description = "Full Okta domain (e.g., yourorg.okta.com) used for API calls in null_resource provisioners"
  type        = string
  default     = ""
}

variable "support_url" {
  description = "End-user support help URL for Okta org configuration"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 2.1: Network Zones
# -----------------------------------------------------------------------------

variable "corporate_gateway_cidrs" {
  description = "List of corporate network gateway CIDRs for the corporate network zone"
  type        = list(string)
  default     = []
}

variable "blocked_ip_cidrs" {
  description = "List of CIDRs to block (known-bad IP ranges)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.3: Anonymizer Blocking (L2)
# -----------------------------------------------------------------------------

variable "blocked_countries" {
  description = "ISO country codes to block via dynamic network zone (L2+)"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR"]
}

# -----------------------------------------------------------------------------
# Section 3.4: Non-Human Identity Governance
# -----------------------------------------------------------------------------

variable "service_app_public_key_e" {
  description = "RSA public key exponent for service app JWT authentication (Base64url)"
  type        = string
  default     = ""
}

variable "service_app_public_key_n" {
  description = "RSA public key modulus for service app JWT authentication (Base64url)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 4.1: Session Timeouts
# -----------------------------------------------------------------------------

variable "session_max_lifetime_minutes" {
  description = "Maximum session lifetime in minutes (720=12h for L1, 480=8h for L2)"
  type        = number
  default     = 720
}

variable "session_max_idle_minutes" {
  description = "Maximum session idle time in minutes (60=1h for L1, 30 for L2)"
  type        = number
  default     = 60
}
