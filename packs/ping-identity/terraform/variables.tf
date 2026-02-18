# =============================================================================
# Ping Identity Hardening Code Pack - Variables
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
# PingOne Provider Configuration
# -----------------------------------------------------------------------------

variable "pingone_client_id" {
  description = "PingOne worker application client ID for API authentication"
  type        = string
}

variable "pingone_client_secret" {
  description = "PingOne worker application client secret"
  type        = string
  sensitive   = true
}

variable "pingone_environment_id" {
  description = "PingOne environment ID to manage"
  type        = string
}

variable "pingone_region" {
  description = "PingOne region code (NorthAmerica, Canada, Europe, AsiaPacific)"
  type        = string
  default     = "NorthAmerica"

  validation {
    condition     = contains(["NorthAmerica", "Canada", "Europe", "AsiaPacific"], var.pingone_region)
    error_message = "Region must be NorthAmerica, Canada, Europe, or AsiaPacific."
  }
}

# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

variable "admin_population_id" {
  description = "PingOne population ID for administrators requiring phishing-resistant MFA"
  type        = string
  default     = ""
}

variable "admin_group_id" {
  description = "PingOne group ID for administrators requiring FIDO2 MFA"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: Least-Privilege Admin Roles
# -----------------------------------------------------------------------------

variable "identity_admin_group_id" {
  description = "PingOne group ID for identity administrators"
  type        = string
  default     = ""
}

variable "app_admin_group_id" {
  description = "PingOne group ID for application administrators"
  type        = string
  default     = ""
}

variable "security_admin_group_id" {
  description = "PingOne group ID for security administrators"
  type        = string
  default     = ""
}

variable "auditor_group_id" {
  description = "PingOne group ID for read-only auditors"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.3: IP-Based Access Restrictions (L2)
# -----------------------------------------------------------------------------

variable "corporate_gateway_cidrs" {
  description = "List of corporate network gateway CIDRs for IP restriction"
  type        = list(string)
  default     = []
}

variable "vpn_egress_cidrs" {
  description = "List of VPN egress CIDRs for IP restriction"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.1: SAML Federation Trust
# -----------------------------------------------------------------------------

variable "saml_assertion_validity_seconds" {
  description = "SAML assertion validity in seconds (300 = 5 minutes max recommended)"
  type        = number
  default     = 300
}

variable "saml_session_timeout_hours" {
  description = "SAML session timeout in hours"
  type        = number
  default     = 8
}

# -----------------------------------------------------------------------------
# Section 2.3: Certificate Lifecycle Management
# -----------------------------------------------------------------------------

variable "cert_expiry_warning_days" {
  description = "Days before certificate expiry to trigger warning alert"
  type        = number
  default     = 90
}

variable "cert_expiry_critical_days" {
  description = "Days before certificate expiry to trigger critical alert"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Section 3.1: OAuth & Token Security
# -----------------------------------------------------------------------------

variable "access_token_lifetime_seconds" {
  description = "OAuth access token lifetime in seconds (3600 = 1 hour max for L1)"
  type        = number
  default     = 3600
}

variable "refresh_token_lifetime_seconds" {
  description = "OAuth refresh token lifetime in seconds (604800 = 7 days L1, 86400 = 24h L2)"
  type        = number
  default     = 604800
}

variable "id_token_lifetime_seconds" {
  description = "OIDC ID token lifetime in seconds (3600 = 1 hour)"
  type        = number
  default     = 3600
}

variable "authorization_code_lifetime_seconds" {
  description = "Authorization code lifetime in seconds (60 = 1 minute)"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Section 4.1: DaVinci Orchestration Security (L2)
# -----------------------------------------------------------------------------

variable "davinci_flow_log_retention_days" {
  description = "DaVinci flow execution log retention in days"
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# Section 5.1: Comprehensive Audit Logging
# -----------------------------------------------------------------------------

variable "audit_log_retention_days" {
  description = "Audit log retention period in days"
  type        = number
  default     = 90
}

variable "siem_webhook_url" {
  description = "Webhook URL for SIEM integration (leave empty to skip)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 6.2: API Client Management
# -----------------------------------------------------------------------------

variable "admin_api_token_lifetime_seconds" {
  description = "Admin API client token lifetime in seconds (900 = 15 minutes)"
  type        = number
  default     = 900
}

variable "scim_token_lifetime_seconds" {
  description = "SCIM provisioner token lifetime in seconds (3600 = 1 hour)"
  type        = number
  default     = 3600
}
