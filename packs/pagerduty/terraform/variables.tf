# =============================================================================
# PagerDuty Hardening Code Pack - Variables
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
# PagerDuty Provider Configuration
# -----------------------------------------------------------------------------

variable "pagerduty_api_token" {
  description = "PagerDuty REST API v2 token for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML Single Sign-On
# -----------------------------------------------------------------------------

variable "sso_login_url" {
  description = "SAML IdP single sign-on URL"
  type        = string
  default     = ""
}

variable "sso_certificate" {
  description = "Base64-encoded SAML IdP X.509 signing certificate (PEM format, without header/footer)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 2.2: SCIM Provisioning (L2)
# -----------------------------------------------------------------------------

variable "scim_token" {
  description = "SCIM API bearer token for automated user lifecycle management (L2+)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 3.1: Role-Based Access
# -----------------------------------------------------------------------------

variable "admin_user_ids" {
  description = "List of PagerDuty user IDs to assign the admin role (limit to 2-3)"
  type        = list(string)
  default     = []
}

variable "team_definitions" {
  description = "List of team definitions for RBAC structure: [{name, description}]"
  type = list(object({
    name        = string
    description = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 3.2: Limit Admin Access
# -----------------------------------------------------------------------------

variable "max_admin_count" {
  description = "Maximum number of admin users allowed (recommended: 2-3)"
  type        = number
  default     = 3
}

variable "observer_user_ids" {
  description = "List of PagerDuty user IDs to assign the read_only_user (Observer) role (L2+ Business/Enterprise)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_log_webhook_url" {
  description = "Webhook URL for forwarding audit log events to SIEM (e.g., Splunk HEC, Elastic)"
  type        = string
  default     = ""
}

variable "audit_webhook_name" {
  description = "Display name for the audit log webhook extension"
  type        = string
  default     = "HTH Audit Log SIEM Forwarder"
}
