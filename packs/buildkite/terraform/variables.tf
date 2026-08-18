# =============================================================================
# Buildkite Hardening Code Pack - Variables
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
# Buildkite Provider Configuration
# -----------------------------------------------------------------------------

variable "buildkite_organization" {
  description = "Buildkite organization slug (from your organization URL)"
  type        = string
}

variable "buildkite_api_token" {
  description = "Buildkite API token with GraphQL and REST API access"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Two-Factor Authentication
# -----------------------------------------------------------------------------

variable "enforce_2fa" {
  description = "Whether to require two-factor authentication for all organization members"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.1: Team Permissions
# -----------------------------------------------------------------------------

variable "teams" {
  description = "Map of teams to create with their configurations"
  type = map(object({
    description                = optional(string, "")
    privacy                    = optional(string, "VISIBLE")
    default_team               = optional(bool, false)
    default_member_role        = optional(string, "MEMBER")
    members_can_create_pipelines = optional(bool, false)
  }))
  default = {
    platform = {
      description                = "Platform engineering team"
      privacy                    = "VISIBLE"
      default_team               = false
      default_member_role        = "MEMBER"
      members_can_create_pipelines = true
    }
    developers = {
      description                = "Development team with read and build access"
      privacy                    = "VISIBLE"
      default_team               = true
      default_member_role        = "MEMBER"
      members_can_create_pipelines = false
    }
    security = {
      description                = "Security team with audit access"
      privacy                    = "SECRET"
      default_team               = false
      default_member_role        = "MEMBER"
      members_can_create_pipelines = false
    }
  }
}

# -----------------------------------------------------------------------------
# Section 2.2: Pipeline Permissions (L2)
# -----------------------------------------------------------------------------

variable "pipelines" {
  description = "Map of pipelines to create with hardened configurations"
  type = map(object({
    repository                   = string
    description                  = optional(string, "")
    default_branch               = optional(string, "main")
    branch_configuration         = optional(string, null)
    skip_intermediate_builds     = optional(bool, true)
    cancel_intermediate_builds   = optional(bool, true)
    cluster_id                   = optional(string, null)
    default_timeout_in_minutes   = optional(number, 60)
    maximum_timeout_in_minutes   = optional(number, 120)
    allow_rebuilds               = optional(bool, true)
  }))
  default = {}
}

variable "pipeline_team_access" {
  description = "Map of pipeline-to-team access grants (key: 'pipeline_key-team_key')"
  type = map(object({
    pipeline_key = string
    team_key     = string
    access_level = string # READ_ONLY, BUILD_AND_READ, or MANAGE_BUILD_AND_READ
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 3.1: Agent Tokens
# -----------------------------------------------------------------------------

variable "agent_tokens" {
  description = "Map of agent tokens to create, keyed by environment name"
  type = map(object({
    description = string
  }))
  default = {
    production = {
      description = "Agent token for production environment"
    }
    staging = {
      description = "Agent token for staging environment"
    }
  }
}

# -----------------------------------------------------------------------------
# Section 3.2: Agent Clusters (L2)
# -----------------------------------------------------------------------------

variable "clusters" {
  description = "Map of agent clusters to create for environment isolation (L2+)"
  type = map(object({
    description = optional(string, "")
    color       = optional(string, null)
    emoji       = optional(string, null)
  }))
  default = {
    production = {
      description = "Production deployment agents - restricted access"
      color       = "#FF0000"
      emoji       = ":lock:"
    }
    development = {
      description = "Development build agents"
      color       = "#00FF00"
      emoji       = ":hammer:"
    }
    security = {
      description = "Security-sensitive build agents"
      color       = "#FF8800"
      emoji       = ":shield:"
    }
  }
}

variable "cluster_queues" {
  description = "Map of cluster queues to create (L2+). Key format: 'cluster_key-queue_name'"
  type = map(object({
    cluster_key = string
    key         = string
    description = optional(string, "")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "allowed_api_ip_addresses" {
  description = "List of IP addresses in CIDR format allowed to access the Buildkite API (L3). Empty list allows all."
  type        = list(string)
  default     = []
}
