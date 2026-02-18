# =============================================================================
# SendGrid Hardening Code Pack - Variables
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
# SendGrid Provider Configuration
# -----------------------------------------------------------------------------

variable "sendgrid_api_key" {
  description = "SendGrid API key with full access for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.2: SAML Single Sign-On (L2)
# -----------------------------------------------------------------------------

variable "sso_name" {
  description = "Display name for the SSO integration"
  type        = string
  default     = "Corporate SSO"
}

variable "sso_signin_url" {
  description = "IdP SAML sign-in URL (e.g., https://idp.example.com/saml/login)"
  type        = string
  default     = ""
}

variable "sso_signout_url" {
  description = "IdP SAML sign-out URL (e.g., https://idp.example.com/saml/logout)"
  type        = string
  default     = ""
}

variable "sso_entity_id" {
  description = "IdP SAML entity ID / issuer URL"
  type        = string
  default     = ""
}

variable "sso_certificate" {
  description = "IdP X.509 public certificate in PEM format for SAML signature verification"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.3: SSO Teammates (L2)
# -----------------------------------------------------------------------------

variable "sso_teammates" {
  description = "List of SSO teammates to provision (requires SSO to be configured)"
  type = list(object({
    email      = string
    first_name = string
    last_name  = string
    is_admin   = optional(bool, false)
    scopes     = optional(set(string), [])
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 1.4: IP Access Management (L2)
# -----------------------------------------------------------------------------

variable "allowed_ips" {
  description = "List of IP addresses allowed to access the SendGrid account (CIDR or single IP)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.1: API Keys
# -----------------------------------------------------------------------------

variable "api_keys" {
  description = "Map of purpose-specific API keys to create with least-privilege scopes"
  type = map(object({
    scopes = set(string)
  }))
  default = {
    transactional_sender = {
      scopes = ["mail.send"]
    }
  }
}

# -----------------------------------------------------------------------------
# Section 3.2: Teammate Permissions
# -----------------------------------------------------------------------------

variable "teammates" {
  description = "List of password-authenticated teammates with role-based scopes"
  type = list(object({
    email    = string
    is_admin = optional(bool, false)
    scopes   = optional(set(string), [])
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 3.3: Sender Authentication
# -----------------------------------------------------------------------------

variable "authenticated_domain" {
  description = "Domain to authenticate for email sending (SPF/DKIM)"
  type        = string
  default     = ""
}

variable "authenticated_domain_subdomain" {
  description = "Subdomain for DNS record generation (optional)"
  type        = string
  default     = ""
}

variable "link_branding_domain" {
  description = "Domain for branded click-tracking links"
  type        = string
  default     = ""
}

variable "link_branding_subdomain" {
  description = "Subdomain for branded link DNS records"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 4.2: Event Webhooks (L2)
# -----------------------------------------------------------------------------

variable "event_webhook_url" {
  description = "HTTPS endpoint URL to receive SendGrid event webhook payloads"
  type        = string
  default     = ""
}
