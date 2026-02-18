# =============================================================================
# Zscaler Hardening Code Pack - Variables
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
# ZPA Provider Configuration
# -----------------------------------------------------------------------------

variable "zpa_client_id" {
  description = "ZPA API client ID for provider authentication"
  type        = string
  sensitive   = true
}

variable "zpa_client_secret" {
  description = "ZPA API client secret for provider authentication"
  type        = string
  sensitive   = true
}

variable "zpa_customer_id" {
  description = "ZPA customer ID (tenant identifier)"
  type        = string
}

variable "zpa_cloud" {
  description = "ZPA cloud environment (production, beta, gov, govus, preview, zscalerten)"
  type        = string
  default     = "production"
}

# -----------------------------------------------------------------------------
# ZIA Provider Configuration
# -----------------------------------------------------------------------------

variable "zia_client_id" {
  description = "ZIA API client ID for provider authentication"
  type        = string
  sensitive   = true
}

variable "zia_client_secret" {
  description = "ZIA API client secret for provider authentication"
  type        = string
  sensitive   = true
}

variable "zia_customer_id" {
  description = "ZIA customer ID (tenant identifier)"
  type        = string
}

variable "zia_cloud" {
  description = "ZIA cloud environment (zscaler, zscalerone, zscalertwo, zscalerthree, zscloud, zscalerbeta, zscalergov)"
  type        = string
  default     = "zscaler"
}

# -----------------------------------------------------------------------------
# Section 2.1: URL Filtering
# -----------------------------------------------------------------------------

variable "url_block_categories" {
  description = "URL categories to block (security-risk categories)"
  type        = list(string)
  default = [
    "MALWARE_SITE",
    "PHISHING",
    "BOTNET",
    "CRYPTOMINING",
    "ADULT_CONTENT",
    "GAMBLING",
    "P2P",
    "ANONYMIZER",
  ]
}

variable "url_caution_categories" {
  description = "URL categories to caution (medium-risk categories)"
  type        = list(string)
  default = [
    "UNCATEGORIZED",
    "NEWLY_REGISTERED_DOMAINS",
    "FILE_SHARING",
    "ONLINE_STORAGE",
  ]
}

# -----------------------------------------------------------------------------
# Section 2.3: Firewall Policies (L2+)
# -----------------------------------------------------------------------------

variable "firewall_allowed_dest_countries" {
  description = "Destination country codes allowed in firewall rules (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Application Segments
# -----------------------------------------------------------------------------

variable "segment_group_name" {
  description = "Name for the default ZPA segment group"
  type        = string
  default     = "HTH-Hardened-Segment-Group"
}

variable "server_group_name" {
  description = "Name for the default ZPA server group"
  type        = string
  default     = "HTH-Hardened-Server-Group"
}

variable "app_connector_group_name" {
  description = "Name of the existing App Connector Group for server group assignment"
  type        = string
  default     = ""
}

variable "application_segments" {
  description = "List of application segments to create in ZPA"
  type = list(object({
    name           = string
    domain_names   = list(string)
    tcp_port_range = list(object({ from = string, to = string }))
    description    = optional(string, "")
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 3.2: Access Policies
# -----------------------------------------------------------------------------

variable "idp_id" {
  description = "ZPA Identity Provider ID for SAML-based access policies"
  type        = string
  default     = ""
}

variable "scim_group_ids" {
  description = "SCIM group attribute IDs to restrict access in ZPA access policies"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.3: Device Posture (L2+)
# -----------------------------------------------------------------------------

variable "posture_min_os_version_windows" {
  description = "Minimum Windows OS version for device posture checks (e.g., 10.0.19045)"
  type        = string
  default     = "10.0.19045"
}

variable "posture_min_os_version_macos" {
  description = "Minimum macOS version for device posture checks (e.g., 14.0)"
  type        = string
  default     = "14.0"
}

# -----------------------------------------------------------------------------
# Section 4.3: Client Connector Lock (L2+)
# -----------------------------------------------------------------------------

variable "cc_lock_password" {
  description = "Password for Client Connector uninstall protection (L2+)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 5.1: SSL Inspection
# -----------------------------------------------------------------------------

variable "ssl_do_not_inspect_urls" {
  description = "URL categories to exclude from SSL inspection (certificate-pinned apps)"
  type        = list(string)
  default = [
    "FINANCIAL_SERVICES",
    "HEALTH_CARE",
    "GOVERNMENT",
  ]
}

# -----------------------------------------------------------------------------
# Section 6.1: Logging and SIEM
# -----------------------------------------------------------------------------

variable "nss_feed_name" {
  description = "Name for the Nanolog Streaming Service feed"
  type        = string
  default     = "HTH-SIEM-Feed"
}

variable "siem_ip" {
  description = "SIEM collector IP address for log streaming"
  type        = string
  default     = ""
}

variable "siem_port" {
  description = "SIEM collector port for log streaming"
  type        = number
  default     = 514
}
