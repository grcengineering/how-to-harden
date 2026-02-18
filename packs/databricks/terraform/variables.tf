# =============================================================================
# Databricks Hardening Code Pack - Variables
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
# Databricks Provider Configuration
# -----------------------------------------------------------------------------

variable "databricks_workspace_url" {
  description = "Databricks workspace URL (e.g., https://adb-1234567890.12.azuredatabricks.net)"
  type        = string
}

variable "databricks_token" {
  description = "Databricks personal access token or service principal token"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

variable "enable_sso_enforcement" {
  description = "Whether to enforce SSO-only login (disables local password login)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Service Principal Security
# -----------------------------------------------------------------------------

variable "service_principals" {
  description = "Map of service principal names to their display names for automation access"
  type = map(object({
    display_name = string
  }))
  default = {
    "svc-etl-pipeline" = { display_name = "SVC - ETL Pipeline" }
    "svc-ml-training"  = { display_name = "SVC - ML Training" }
    "svc-reporting"    = { display_name = "SVC - BI Reporting" }
  }
}

# -----------------------------------------------------------------------------
# Section 1.3: IP Access Lists (L2)
# -----------------------------------------------------------------------------

variable "allowed_ip_cidrs" {
  description = "List of CIDR blocks allowed to access the Databricks workspace (L2+)"
  type        = list(string)
  default     = []
}

variable "blocked_ip_cidrs" {
  description = "List of CIDR blocks to deny access to the Databricks workspace (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Cluster Policies
# -----------------------------------------------------------------------------

variable "allowed_spark_versions" {
  description = "List of allowed Databricks Runtime versions for cluster policies"
  type        = list(string)
  default     = ["13.3.x-scala2.12", "14.3.x-scala2.12", "15.4.x-scala2.12"]
}

variable "allowed_node_types" {
  description = "List of allowed instance/node types for cluster policies"
  type        = list(string)
  default     = ["Standard_DS3_v2", "Standard_DS4_v2", "i3.xlarge", "i3.2xlarge"]
}

variable "autotermination_minutes_default" {
  description = "Default auto-termination in minutes for idle clusters"
  type        = number
  default     = 30
}

variable "autotermination_minutes_max" {
  description = "Maximum auto-termination in minutes allowed by cluster policy"
  type        = number
  default     = 120
}

# -----------------------------------------------------------------------------
# Section 3.2: Network Isolation (L2)
# -----------------------------------------------------------------------------

variable "enable_no_public_ip" {
  description = "Disable public IP addresses on cluster nodes (L2+)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 4.1: Secret Scopes
# -----------------------------------------------------------------------------

variable "secret_scopes" {
  description = "Map of Databricks secret scope names to create"
  type = map(object({
    initial_manage_principal = string
  }))
  default = {
    "production-secrets" = { initial_manage_principal = "admins" }
  }
}

# -----------------------------------------------------------------------------
# Section 5.1: Security Monitoring
# -----------------------------------------------------------------------------

variable "enable_verbose_audit_logs" {
  description = "Enable verbose audit logging for workspace events"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 4.2: External Secret Store (L2)
# -----------------------------------------------------------------------------

variable "azure_keyvault_resource_id" {
  description = "Azure Key Vault resource ID for external secret scope (L2+, Azure only)"
  type        = string
  default     = ""
}

variable "azure_keyvault_dns_name" {
  description = "Azure Key Vault DNS name (e.g., https://my-vault.vault.azure.net/)"
  type        = string
  default     = ""
}
