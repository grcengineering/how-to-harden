# =============================================================================
# Oracle HCM Cloud Hardening Code Pack - Variables
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
# OCI Provider Configuration
# -----------------------------------------------------------------------------

variable "oci_tenancy_ocid" {
  description = "OCID of the OCI tenancy"
  type        = string
}

variable "oci_user_ocid" {
  description = "OCID of the OCI user for API authentication"
  type        = string
}

variable "oci_fingerprint" {
  description = "Fingerprint of the OCI API signing key"
  type        = string
}

variable "oci_private_key_path" {
  description = "Path to the OCI API signing private key PEM file"
  type        = string
}

variable "oci_region" {
  description = "OCI region (e.g., us-ashburn-1, eu-frankfurt-1)"
  type        = string
  default     = "us-ashburn-1"
}

# -----------------------------------------------------------------------------
# IDCS Configuration
# -----------------------------------------------------------------------------

variable "idcs_domain_url" {
  description = "Oracle IDCS domain URL (e.g., https://idcs-abc123.identity.oraclecloud.com)"
  type        = string
}

variable "identity_domain_id" {
  description = "OCID of the OCI Identity Domain (IDCS) for HCM federation"
  type        = string
}

variable "idcs_compartment_id" {
  description = "OCID of the compartment containing the identity domain"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA Enforcement
# -----------------------------------------------------------------------------

variable "mfa_enabled_factors" {
  description = "List of MFA factors to enable (TOTP, PUSH, FIDO2, SMS, EMAIL)"
  type        = list(string)
  default     = ["TOTP", "PUSH", "FIDO2"]
}

variable "sso_idp_name" {
  description = "Display name for the federated identity provider"
  type        = string
  default     = "Corporate SSO"
}

variable "sso_idp_metadata_url" {
  description = "SAML metadata URL for the federated identity provider (leave empty to skip IdP creation)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: Security Roles
# -----------------------------------------------------------------------------

variable "it_security_manager_group_name" {
  description = "Name of the IT Security Manager group in IDCS"
  type        = string
  default     = "HTH-IT-Security-Managers"
}

variable "hcm_admin_group_name" {
  description = "Name of the HCM Application Administrator group in IDCS"
  type        = string
  default     = "HTH-HCM-Admins"
}

variable "hr_analyst_group_name" {
  description = "Name of the HR Analyst (read-only) group in IDCS"
  type        = string
  default     = "HTH-HR-Analysts"
}

# -----------------------------------------------------------------------------
# Section 1.3: Security Profiles
# -----------------------------------------------------------------------------

variable "restrict_compensation_visibility" {
  description = "Restrict compensation data to authorized roles only"
  type        = bool
  default     = true
}

variable "restrict_payroll_data" {
  description = "Restrict payroll data access to authorized roles only"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.1: REST API Security
# -----------------------------------------------------------------------------

variable "oauth_client_name" {
  description = "Display name for the hardened HCM REST API OAuth client"
  type        = string
  default     = "HTH-HCM-API-Client"
}

variable "oauth_allowed_grant_types" {
  description = "Allowed OAuth grant types for the HCM API client"
  type        = list(string)
  default     = ["authorization_code"]
}

variable "oauth_allowed_scopes" {
  description = "Allowed API scopes for the HCM REST API client (minimum required)"
  type        = list(string)
  default     = []
}

variable "oauth_redirect_uris" {
  description = "Exact-match redirect URIs for the HCM API OAuth client"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.2: HCM Data Loader (HDL) Security (L2+)
# -----------------------------------------------------------------------------

variable "hdl_authorized_group_name" {
  description = "Name of the group authorized for HDL bulk operations (L2+)"
  type        = string
  default     = "HTH-HDL-Authorized-Users"
}

# -----------------------------------------------------------------------------
# Section 3.1: Data Encryption
# -----------------------------------------------------------------------------

variable "oci_vault_id" {
  description = "OCID of the OCI Vault for customer-managed encryption keys (leave empty to use Oracle-managed keys)"
  type        = string
  default     = ""
}

variable "oci_key_id" {
  description = "OCID of the master encryption key in OCI Vault (leave empty to use Oracle-managed keys)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 3.2: Data Retention and Purge
# -----------------------------------------------------------------------------

variable "audit_retention_days" {
  description = "Number of days to retain audit log data (minimum 365)"
  type        = number
  default     = 365

  validation {
    condition     = var.audit_retention_days >= 365
    error_message = "Audit retention must be at least 365 days."
  }
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Policies
# -----------------------------------------------------------------------------

variable "enable_auth_event_auditing" {
  description = "Enable auditing for authentication events"
  type        = bool
  default     = true
}

variable "enable_data_access_auditing" {
  description = "Enable auditing for data access (read/write)"
  type        = bool
  default     = true
}

variable "enable_config_change_auditing" {
  description = "Enable auditing for security configuration changes"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 4.2: Monitor Integration Activity (L2+)
# -----------------------------------------------------------------------------

variable "api_rate_limit_threshold" {
  description = "API call count threshold per hour that triggers an alarm (L2+)"
  type        = number
  default     = 500
}

variable "alarm_notification_topic_id" {
  description = "OCID of the OCI Notification Service topic for alarm delivery (leave empty to create one)"
  type        = string
  default     = ""
}

variable "alarm_notification_email" {
  description = "Email address for alarm notifications (used when creating a new notification topic)"
  type        = string
  default     = ""
}
