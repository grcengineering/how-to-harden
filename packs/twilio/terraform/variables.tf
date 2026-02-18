# =============================================================================
# Twilio Hardening Code Pack - Variables
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
# Twilio Provider Configuration
# -----------------------------------------------------------------------------

variable "twilio_account_sid" {
  description = "Twilio Account SID (starts with AC)"
  type        = string

  validation {
    condition     = can(regex("^AC", var.twilio_account_sid))
    error_message = "Twilio Account SID must start with 'AC'."
  }
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML SSO Configuration
# -----------------------------------------------------------------------------

variable "sso_saml_issuer" {
  description = "SAML IdP Issuer URL for SSO configuration"
  type        = string
  default     = ""
}

variable "sso_saml_url" {
  description = "SAML IdP SSO URL"
  type        = string
  default     = ""
}

variable "sso_saml_certificate" {
  description = "SAML IdP X.509 signing certificate (PEM-encoded)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 2.1: User Role Configuration
# -----------------------------------------------------------------------------

variable "restricted_role_users" {
  description = "Map of user emails to their assigned Twilio role (developer, billing, support)"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Section 2.2: Subaccount Configuration (L2)
# -----------------------------------------------------------------------------

variable "subaccounts" {
  description = "List of subaccount friendly names to create for environment isolation"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: API Key Configuration
# -----------------------------------------------------------------------------

variable "api_key_friendly_name" {
  description = "Friendly name for the standard API key"
  type        = string
  default     = "hth-hardened-api-key"
}

variable "create_api_key" {
  description = "Whether to create a hardened standard API key"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.2: Webhook Security (L2)
# -----------------------------------------------------------------------------

variable "webhook_allowed_ip_cidrs" {
  description = "List of allowed IP CIDRs for webhook callback origins"
  type        = list(string)
  default     = []
}
