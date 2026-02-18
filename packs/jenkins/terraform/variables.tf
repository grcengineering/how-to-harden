# =============================================================================
# Jenkins Hardening Code Pack - Variables
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
# Jenkins Provider Configuration
# -----------------------------------------------------------------------------

variable "jenkins_server_url" {
  description = "URL of the Jenkins server (e.g., https://jenkins.example.com)"
  type        = string
}

variable "jenkins_username" {
  description = "Jenkins admin username for API authentication"
  type        = string
}

variable "jenkins_password" {
  description = "Jenkins admin password or API token for authentication"
  type        = string
  sensitive   = true
}

variable "jenkins_ca_cert" {
  description = "Path to Jenkins self-signed CA certificate (leave empty if using trusted CA)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: SSO Configuration (L2+)
# -----------------------------------------------------------------------------

variable "sso_type" {
  description = "SSO type to configure: 'saml', 'ldap', or 'none'"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["saml", "ldap", "none"], var.sso_type)
    error_message = "SSO type must be 'saml', 'ldap', or 'none'."
  }
}

variable "saml_idp_metadata_url" {
  description = "SAML IdP metadata URL (required when sso_type = 'saml')"
  type        = string
  default     = ""
}

variable "saml_username_attribute" {
  description = "SAML attribute name for username mapping"
  type        = string
  default     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
}

variable "saml_email_attribute" {
  description = "SAML attribute name for email mapping"
  type        = string
  default     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
}

variable "saml_group_attribute" {
  description = "SAML attribute name for group membership mapping"
  type        = string
  default     = "http://schemas.xmlsoap.org/claims/Group"
}

variable "ldap_server_url" {
  description = "LDAP server URL (e.g., ldaps://ldap.example.com:636)"
  type        = string
  default     = ""
}

variable "ldap_root_dn" {
  description = "LDAP root distinguished name (e.g., dc=example,dc=com)"
  type        = string
  default     = ""
}

variable "ldap_user_search_base" {
  description = "LDAP user search base (e.g., ou=users)"
  type        = string
  default     = "ou=users"
}

variable "ldap_user_search_filter" {
  description = "LDAP user search filter"
  type        = string
  default     = "uid={0}"
}

variable "ldap_group_search_base" {
  description = "LDAP group search base (e.g., ou=groups)"
  type        = string
  default     = "ou=groups"
}

variable "ldap_manager_dn" {
  description = "LDAP manager DN for bind authentication"
  type        = string
  default     = ""
}

variable "ldap_manager_password" {
  description = "LDAP manager password for bind authentication"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 2.1: Matrix-Based Security - Folder Structure
# -----------------------------------------------------------------------------

variable "team_folders" {
  description = "Map of team folder names to descriptions for project-based authorization"
  type = map(object({
    description = string
    permissions = optional(list(string), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.2: Project-Based Matrix Authorization (L2+)
# -----------------------------------------------------------------------------

variable "project_folders" {
  description = "Map of project folder names with parent folders and per-project permissions (L2+)"
  type = map(object({
    description   = string
    parent_folder = optional(string, "")
    permissions   = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.3: Role-Based Access Control (L2+)
# -----------------------------------------------------------------------------

variable "enable_rbac" {
  description = "Enable role-based authorization strategy instead of matrix (L2+, requires Role Strategy Plugin)"
  type        = bool
  default     = false
}

variable "developer_users" {
  description = "List of usernames to assign the developer role (build and read permissions)"
  type        = list(string)
  default     = []
}

variable "viewer_users" {
  description = "List of usernames to assign the viewer role (read-only permissions)"
  type        = list(string)
  default     = []
}

variable "rbac_item_roles" {
  description = "List of item-level RBAC roles with pattern-based project matching"
  type = list(object({
    name        = string
    description = string
    pattern     = string
    permissions = list(string)
    users       = list(string)
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 2.4: Script Console - Admin Users
# -----------------------------------------------------------------------------

variable "admin_users" {
  description = "List of admin usernames who should have Overall/Administer (script console access)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.2: Disable Builds on Controller
# -----------------------------------------------------------------------------

variable "controller_executors" {
  description = "Number of executors on the built-in controller node (set to 0 to disable builds on controller)"
  type        = number
  default     = 0
}

variable "controller_label" {
  description = "Label for the built-in controller node (use restrictive label to prevent job assignment)"
  type        = string
  default     = "do-not-use"
}

# -----------------------------------------------------------------------------
# Section 3.3: Ephemeral Agents (L2+)
# -----------------------------------------------------------------------------

variable "cloud_agent_type" {
  description = "Cloud agent type for ephemeral builds: 'kubernetes', 'docker', or 'none'"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["kubernetes", "docker", "none"], var.cloud_agent_type)
    error_message = "Cloud agent type must be 'kubernetes', 'docker', or 'none'."
  }
}

variable "k8s_server_url" {
  description = "Kubernetes API server URL for cloud agents"
  type        = string
  default     = "https://kubernetes.default"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for Jenkins agent pods"
  type        = string
  default     = "jenkins"
}

variable "k8s_max_containers" {
  description = "Maximum number of concurrent Kubernetes agent containers"
  type        = string
  default     = "10"
}

variable "docker_host_uri" {
  description = "Docker host URI for cloud agents (e.g., unix:///var/run/docker.sock)"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "docker_max_instances" {
  description = "Maximum number of concurrent Docker agent instances"
  type        = string
  default     = "5"
}

variable "agent_image" {
  description = "Container image for ephemeral build agents"
  type        = string
  default     = "jenkins/inbound-agent:latest"
}

variable "agent_cpu_limit" {
  description = "CPU resource limit for Kubernetes agent containers"
  type        = string
  default     = "500m"
}

variable "agent_memory_limit" {
  description = "Memory resource limit for Kubernetes agent containers"
  type        = string
  default     = "512Mi"
}

# -----------------------------------------------------------------------------
# Section 3.4: Secure Agent Communication
# -----------------------------------------------------------------------------

variable "agent_inbound_port" {
  description = "Fixed TCP port for inbound JNLP agent connections (use fixed port for firewall rules)"
  type        = number
  default     = 50000
}

# -----------------------------------------------------------------------------
# Section 4.1: CSRF Protection
# -----------------------------------------------------------------------------

variable "csrf_proxy_compatibility" {
  description = "Enable CSRF proxy compatibility mode (set to true if Jenkins is behind a reverse proxy)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 4.2: Credential Scoping
# -----------------------------------------------------------------------------

variable "credential_domains" {
  description = "Map of credential domain folder names for scoped credential management"
  type = map(object({
    description = string
  }))
  default = {
    "production-deployments" = {
      description = "Credentials scoped to production deployment jobs only"
    }
    "testing-resources" = {
      description = "Credentials scoped to testing and QA jobs"
    }
    "third-party-integrations" = {
      description = "Credentials for third-party service integrations"
    }
  }
}

# -----------------------------------------------------------------------------
# Section 4.4: Secure Jenkinsfile - Template Job (L2+)
# -----------------------------------------------------------------------------

variable "create_secure_pipeline_template" {
  description = "Create a secure pipeline template job demonstrating hardened Jenkinsfile practices"
  type        = bool
  default     = true
}

variable "secure_pipeline_agent_label" {
  description = "Agent label for the secure pipeline template job"
  type        = string
  default     = "secure-agent"
}

variable "build_timeout_hours" {
  description = "Maximum build time in hours for the secure pipeline template"
  type        = number
  default     = 1
}

variable "builds_to_keep" {
  description = "Number of old builds to retain in the secure pipeline template"
  type        = number
  default     = 10
}

# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

variable "create_security_views" {
  description = "Create Jenkins views for security monitoring and audit visibility"
  type        = bool
  default     = true
}

variable "monitored_projects" {
  description = "List of project names to include in the security monitoring view"
  type        = list(string)
  default     = []
}

variable "audit_log_path" {
  description = "File path for the audit trail log"
  type        = string
  default     = "/var/log/jenkins/audit.log"
}

variable "audit_log_size_mb" {
  description = "Maximum audit log file size in MB before rotation"
  type        = number
  default     = 100
}

variable "audit_log_rotate_count" {
  description = "Number of rotated audit log files to retain"
  type        = number
  default     = 5
}

variable "syslog_server" {
  description = "Syslog server hostname for SIEM integration (leave empty to disable)"
  type        = string
  default     = ""
}

variable "syslog_port" {
  description = "Syslog server port"
  type        = number
  default     = 514
}
