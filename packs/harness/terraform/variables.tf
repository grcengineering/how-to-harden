# =============================================================================
# Harness Hardening Code Pack - Variables
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
# Harness Provider Configuration
# -----------------------------------------------------------------------------

variable "harness_endpoint" {
  description = "Harness API endpoint URL (e.g., https://app.harness.io/gateway)"
  type        = string
  default     = "https://app.harness.io/gateway"
}

variable "harness_account_id" {
  description = "Harness account identifier"
  type        = string
}

variable "harness_platform_api_key" {
  description = "Harness platform API key (PAT or SAT) for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML Single Sign-On
# -----------------------------------------------------------------------------

variable "saml_provider_name" {
  description = "Display name for the SAML SSO provider in Harness"
  type        = string
  default     = "Corporate SSO"
}

variable "saml_metadata_url" {
  description = "URL to the IdP SAML metadata XML document"
  type        = string
  default     = ""
}

variable "saml_metadata_xml" {
  description = "Raw SAML metadata XML from the IdP (used if saml_metadata_url is empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "saml_group_attribute" {
  description = "SAML attribute name containing group membership for authorization mapping"
  type        = string
  default     = "groups"
}

variable "saml_entity_id" {
  description = "SAML Entity ID (audience restriction) for the Harness service provider"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

variable "enforce_2fa" {
  description = "Whether to enforce two-factor authentication for all users"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.3: IP Allowlisting (L2)
# -----------------------------------------------------------------------------

variable "allowed_source_cidrs" {
  description = "List of CIDR ranges to allow access from (L2+). Leave empty to skip."
  type        = list(string)
  default     = []
}

variable "ip_allowlist_name" {
  description = "Name for the IP allowlist configuration"
  type        = string
  default     = "Corporate Network Allowlist"
}

# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

variable "custom_roles" {
  description = "Map of custom roles to create. Key is role identifier, value is config."
  type = map(object({
    name               = string
    permissions        = list(string)
    allowed_scope_levels = optional(list(string), ["project"])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.2: Organization/Project Hierarchy (L2)
# -----------------------------------------------------------------------------

variable "organizations" {
  description = "Map of organizations to create for access isolation (L2+). Key is identifier."
  type = map(object({
    name        = string
    description = optional(string, "")
  }))
  default = {}
}

variable "projects" {
  description = "Map of projects to create within organizations (L2+). Key is identifier."
  type = map(object({
    name        = string
    org_id      = string
    description = optional(string, "")
    color       = optional(string, "#0063F7")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.3: Limit Admin Access
# -----------------------------------------------------------------------------

variable "admin_user_group_name" {
  description = "Name of the restricted admin user group"
  type        = string
  default     = "Platform Administrators"
}

variable "admin_user_emails" {
  description = "List of email addresses for platform administrators (limit to 2-3)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Secret Manager
# -----------------------------------------------------------------------------

variable "secret_manager_type" {
  description = "Type of external secret manager: vault, aws, azure, gcp, or builtin"
  type        = string
  default     = "builtin"

  validation {
    condition     = contains(["builtin", "vault", "aws", "azure", "gcp"], var.secret_manager_type)
    error_message = "Secret manager type must be one of: builtin, vault, aws, azure, gcp."
  }
}

variable "vault_url" {
  description = "HashiCorp Vault server URL (required when secret_manager_type = vault)"
  type        = string
  default     = ""
}

variable "vault_token" {
  description = "HashiCorp Vault authentication token (required when secret_manager_type = vault)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vault_secret_engine" {
  description = "Vault secret engine name (e.g., secret, kv-v2)"
  type        = string
  default     = "secret"
}

variable "vault_renew_interval_minutes" {
  description = "Vault token renewal interval in minutes"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# Section 3.2: Secret Access (L2)
# -----------------------------------------------------------------------------

variable "secret_resource_group_name" {
  description = "Name for the secret-scoped resource group (L2+)"
  type        = string
  default     = "Secret Managers"
}

variable "secret_manager_role_name" {
  description = "Name for the secret manager access role (L2+)"
  type        = string
  default     = "Secret Manager Operator"
}

# -----------------------------------------------------------------------------
# Section 4.1: Pipeline Governance (L2)
# -----------------------------------------------------------------------------

variable "governance_policies" {
  description = "Map of OPA governance policies to create (L2+). Key is policy identifier."
  type = map(object({
    name  = string
    rego  = string
  }))
  default = {}
}

variable "require_prod_approval" {
  description = "Require manual approval for production pipeline deployments (L2+)"
  type        = bool
  default     = true
}

variable "approval_user_group_id" {
  description = "Harness user group identifier for production approval gates (L2+)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 4.2: Audit Trail
# -----------------------------------------------------------------------------

variable "audit_log_streaming_enabled" {
  description = "Enable audit log streaming to an external destination"
  type        = bool
  default     = false
}

variable "audit_retention_days" {
  description = "Number of days to retain audit logs (L3 = 365+, L2 = 180, L1 = 90)"
  type        = number
  default     = 90
}
