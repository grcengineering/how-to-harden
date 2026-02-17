# =============================================================================
# Snowflake Hardening Code Pack - Variables
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
# Snowflake Provider Configuration
# -----------------------------------------------------------------------------

variable "snowflake_account" {
  description = "Snowflake account identifier (e.g., xy12345.us-east-1)"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake username with ACCOUNTADMIN or SECURITYADMIN role"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 1.1: MFA Enforcement
# -----------------------------------------------------------------------------

variable "create_example_service_account" {
  description = "Create an example service account with key-pair auth (for demonstration)"
  type        = bool
  default     = false
}

variable "service_account_rsa_public_key" {
  description = "RSA public key for the example service account (PEM format, no header/footer)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.3: RBAC
# -----------------------------------------------------------------------------

variable "target_database" {
  description = "Target database for RBAC grants and masking policies"
  type        = string
  default     = ""
}

variable "target_schema" {
  description = "Target schema for masking policies and row access policies"
  type        = string
  default     = "PUBLIC"
}

# -----------------------------------------------------------------------------
# Section 2.1: Network Policies
# -----------------------------------------------------------------------------

variable "allowed_ip_list" {
  description = "List of allowed IP addresses/CIDRs for the corporate network policy"
  type        = list(string)
  default     = []
}

variable "blocked_ip_list" {
  description = "List of blocked IP addresses/CIDRs"
  type        = list(string)
  default     = []
}

variable "service_account_allowed_ips" {
  description = "Allowed IPs for service account network policy (empty = skip)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: OAuth Scopes
# -----------------------------------------------------------------------------

variable "oauth_redirect_uri" {
  description = "OAuth redirect URI for the custom OAuth integration"
  type        = string
  default     = "https://localhost/callback"
}

variable "oauth_refresh_token_validity" {
  description = "OAuth refresh token validity in seconds (default: 86400 = 24h)"
  type        = number
  default     = 86400
}

# -----------------------------------------------------------------------------
# Section 3.2: External OAuth (L2)
# -----------------------------------------------------------------------------

variable "external_oauth_type" {
  description = "External OAuth provider type (AZURE, OKTA, PING_FEDERATE, CUSTOM)"
  type        = string
  default     = "CUSTOM"
}

variable "external_oauth_issuer" {
  description = "External OAuth token issuer URL"
  type        = string
  default     = ""
}

variable "external_oauth_jws_keys_url" {
  description = "External OAuth JWS keys URL for token validation"
  type        = string
  default     = ""
}
