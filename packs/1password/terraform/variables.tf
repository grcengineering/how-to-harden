# =============================================================================
# 1Password Hardening Code Pack - Variables
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
# 1Password Provider Configuration
# -----------------------------------------------------------------------------

variable "op_service_account_token" {
  description = "1Password Service Account token for Terraform provider authentication"
  type        = string
  sensitive   = true
}

variable "op_connect_url" {
  description = "1Password Connect server URL (e.g., https://connect.yourcompany.com)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 3.1: Vault Permissions
# -----------------------------------------------------------------------------

variable "vault_configs" {
  description = "List of vaults to create with their access configurations"
  type = list(object({
    name        = string
    description = string
  }))
  default = [
    {
      name        = "Infrastructure"
      description = "Server credentials, API keys, and infrastructure secrets"
    },
    {
      name        = "Team Shared"
      description = "Shared team credentials and service accounts"
    },
    {
      name        = "Executive"
      description = "Sensitive business credentials -- restricted access"
    }
  ]
}

# -----------------------------------------------------------------------------
# Section 2.2: Firewall Rules (L2)
# -----------------------------------------------------------------------------

variable "allowed_countries" {
  description = "ISO 3166-1 alpha-2 country codes to allow (L2+ firewall rules)"
  type        = list(string)
  default     = ["US", "CA", "GB"]
}

variable "allowed_ip_cidrs" {
  description = "Corporate IP CIDRs to allow for 1Password access (L3 firewall rules)"
  type        = list(string)
  default     = []
}

variable "denied_countries" {
  description = "ISO 3166-1 alpha-2 country codes to block (L2+ firewall rules)"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR"]
}

# -----------------------------------------------------------------------------
# Section 2.1: Account Password Policy
# -----------------------------------------------------------------------------

variable "master_password_min_length" {
  description = "Minimum master password length (10 for L1, 12 for L2, 14 for L3)"
  type        = number
  default     = 14
}

# -----------------------------------------------------------------------------
# Section 3.2: Item Sharing Policies (L2)
# -----------------------------------------------------------------------------

variable "allow_item_sharing" {
  description = "Whether to allow item sharing between vault members"
  type        = bool
  default     = true
}

variable "allow_guest_sharing" {
  description = "Whether to allow sharing items with guests (L2: false)"
  type        = bool
  default     = false
}

variable "share_link_expiry_hours" {
  description = "Default expiration for shared links in hours (L3: 24)"
  type        = number
  default     = 72
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging / SIEM Integration
# -----------------------------------------------------------------------------

variable "siem_endpoint" {
  description = "SIEM webhook endpoint for 1Password Events API streaming"
  type        = string
  default     = ""
}

variable "events_api_token" {
  description = "1Password Events API bearer token for SIEM integration"
  type        = string
  sensitive   = true
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO Configuration
# -----------------------------------------------------------------------------

variable "idp_sso_url" {
  description = "Identity Provider SSO URL for SAML configuration"
  type        = string
  default     = ""
}

variable "idp_entity_id" {
  description = "Identity Provider Entity ID for SAML configuration"
  type        = string
  default     = ""
}

variable "idp_certificate" {
  description = "Identity Provider X.509 certificate (PEM-encoded) for SAML"
  type        = string
  sensitive   = true
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: SCIM Provisioning (L2)
# -----------------------------------------------------------------------------

variable "scim_bridge_url" {
  description = "1Password SCIM bridge URL for automated provisioning"
  type        = string
  default     = ""
}

variable "scim_bearer_token" {
  description = "SCIM bearer token for identity provider integration"
  type        = string
  sensitive   = true
  default     = ""
}
