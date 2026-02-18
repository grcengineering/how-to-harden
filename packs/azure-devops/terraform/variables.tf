# =============================================================================
# Azure DevOps Hardening Code Pack - Variables
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
# Azure DevOps Provider Configuration
# -----------------------------------------------------------------------------

variable "org_service_url" {
  description = "Azure DevOps organization URL (e.g., https://dev.azure.com/your-org)"
  type        = string
}

variable "personal_access_token" {
  description = "Azure DevOps personal access token for provider authentication"
  type        = string
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Section 1: Authentication & Access Controls
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Azure DevOps project name to apply hardening controls"
  type        = string
}

variable "project_id" {
  description = "Azure DevOps project ID (used for permission and policy resources)"
  type        = string
  default     = ""
}

variable "project_administrators_group" {
  description = "Display name of the Project Administrators group"
  type        = string
  default     = "Project Administrators"
}

variable "build_administrators_group" {
  description = "Display name of the Build Administrators group"
  type        = string
  default     = "Build Administrators"
}

variable "contributors_group" {
  description = "Display name of the Contributors group"
  type        = string
  default     = "Contributors"
}

variable "security_reviewers_group_name" {
  description = "Name of the security reviewers group to create for approval gates"
  type        = string
  default     = "Security Reviewers"
}

variable "security_reviewer_members" {
  description = "List of user principal names to add to the security reviewers group"
  type        = list(string)
  default     = []
}

variable "pat_max_lifetime_days" {
  description = "Maximum personal access token lifetime in days (L1: 90, L2: 60, L3: 30)"
  type        = number
  default     = 90
}


# -----------------------------------------------------------------------------
# Section 2: Service Connection Security
# -----------------------------------------------------------------------------

variable "azure_subscription_id" {
  description = "Azure subscription ID for workload identity federation service connection"
  type        = string
  default     = ""
}

variable "azure_subscription_name" {
  description = "Azure subscription display name for service connection"
  type        = string
  default     = ""
}

variable "service_principal_id" {
  description = "Azure AD service principal (application) ID for workload identity federation"
  type        = string
  default     = ""
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID for workload identity federation"
  type        = string
  default     = ""
}

variable "service_connection_approvers" {
  description = "List of user principal names who can approve service connection usage (L2+)"
  type        = list(string)
  default     = []
}

variable "legacy_service_connection_ids" {
  description = "List of existing service connection IDs with stored credentials to audit"
  type        = list(string)
  default     = []
}


# -----------------------------------------------------------------------------
# Section 3: Pipeline Security
# -----------------------------------------------------------------------------

variable "production_environment_name" {
  description = "Name of the production environment for pipeline approvals"
  type        = string
  default     = "production"
}

variable "staging_environment_name" {
  description = "Name of the staging environment"
  type        = string
  default     = "staging"
}

variable "deployment_approvers" {
  description = "List of user principal names who can approve production deployments"
  type        = list(string)
  default     = []
}

variable "agent_pool_name" {
  description = "Name of the self-hosted production agent pool to create"
  type        = string
  default     = "Production-Agents"
}

variable "security_agent_pool_name" {
  description = "Name of the isolated security scanning agent pool (L2+)"
  type        = string
  default     = "Security-Agents"
}


# -----------------------------------------------------------------------------
# Section 4: Repository Security
# -----------------------------------------------------------------------------

variable "repository_name" {
  description = "Name of the primary repository to apply branch policies"
  type        = string
  default     = ""
}

variable "repository_id" {
  description = "Git repository ID for branch policy resources"
  type        = string
  default     = ""
}

variable "default_branch" {
  description = "Default branch name for branch policies (e.g., refs/heads/main)"
  type        = string
  default     = "refs/heads/main"
}

variable "min_reviewer_count" {
  description = "Minimum number of reviewers for pull requests (L1: 1, L2: 2, L3: 3)"
  type        = number
  default     = 1
}

variable "build_validation_definition_id" {
  description = "Build definition ID for branch policy build validation"
  type        = number
  default     = 0
}

variable "pipeline_yaml_reviewers" {
  description = "List of user principal names required to review pipeline YAML changes (L2+)"
  type        = list(string)
  default     = []
}


# -----------------------------------------------------------------------------
# Section 5: Variable & Secret Management
# -----------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Azure Key Vault name to link for production secrets variable group"
  type        = string
  default     = ""
}

variable "key_vault_service_connection_id" {
  description = "Service connection ID with access to the Key Vault"
  type        = string
  default     = ""
}

variable "key_vault_secrets" {
  description = "Map of Key Vault secret names to include in the linked variable group"
  type        = map(string)
  default     = {}
}


# -----------------------------------------------------------------------------
# Section 6: Monitoring & Detection
# -----------------------------------------------------------------------------

variable "enable_audit_stream" {
  description = "Whether to enable audit log streaming (requires Azure DevOps audit feature)"
  type        = bool
  default     = false
}
