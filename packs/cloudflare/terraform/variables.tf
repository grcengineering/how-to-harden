# =============================================================================
# Cloudflare Hardening Code Pack - Shared Variables
# How to Harden (howtoharden.com)
#
# One declaration per input used by the hth-cloudflare-*.tf packs, so each pack
# validates on its own (pack + providers.tf + this file) and all of them
# validate together.
# =============================================================================

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for zone-scoped resources (Access applications in 2.1/5.2, the tunnel DNS record in 5.1)"
  type        = string
}

variable "corporate_domain" {
  description = "Email domain of the organization, e.g. example.com (Access include rules)"
  type        = string
}

variable "allowed_idp_ids" {
  description = "IDs of the Access identity providers allowed to authenticate (1.3, 2.1, 5.2)"
  type        = list(string)
}

# 1.1 Identity provider (OIDC)
variable "oidc_client_id" {
  description = "OIDC client ID from the identity provider application"
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC client secret from the identity provider application"
  type        = string
  sensitive   = true
}

variable "oidc_auth_url" {
  description = "IdP authorization endpoint"
  type        = string
}

variable "oidc_token_url" {
  description = "IdP token endpoint"
  type        = string
}

variable "oidc_certs_url" {
  description = "IdP jwks_uri endpoint used to verify token signatures"
  type        = string
}

# 1.4 Admin roles
variable "zt_admin_email" {
  description = "Member to receive the Cloudflare Zero Trust role"
  type        = string
}

variable "audit_viewer_email" {
  description = "Member to receive the Audit Logs Viewer role"
  type        = string
}

# 1.5 Scoped account token
variable "automation_token_permission_groups" {
  description = "Permission group names granted to the automation token (least privilege)"
  type        = list(string)
  default     = ["Zero Trust Read"]
}

variable "automation_token_expires_on" {
  description = "UTC expiry timestamp for the automation token, e.g. 2027-01-01T00:00:00Z"
  type        = string
}

variable "automation_token_allowed_cidrs" {
  description = "Client IP ranges allowed to use the automation token"
  type        = list(string)
}

# 2.1 / 2.2 / 5.x applications and groups
variable "internal_app_domain" {
  description = "Hostname of the internal application protected in 2.1"
  type        = string
}

variable "sensitive_app_domain" {
  description = "Hostname of the application that requires WARP in 2.2"
  type        = string
}

variable "employees_group_id" {
  description = "Access group ID allowed through the tunnel application in 5.2"
  type        = string
}

variable "min_os_version" {
  description = "Minimum macOS version for the 2.3 OS version posture check, e.g. 14.0.0"
  type        = string
}

# 2.4 Access for Infrastructure
variable "ssh_target_hostname" {
  description = "Target hostname registered for SSH access"
  type        = string
}

variable "ssh_target_ip" {
  description = "Private IPv4 address of the SSH target"
  type        = string
}

variable "ssh_target_virtual_network_id" {
  description = "Virtual network ID the target is reachable through"
  type        = string
}

variable "ssh_allowed_group_id" {
  description = "Access group ID allowed to open SSH sessions"
  type        = string
}

variable "ssh_allowed_usernames" {
  description = "Unix usernames the group may log in as (avoid root)"
  type        = list(string)
}

# 2.5 Risk behaviors
variable "risk_behaviors_left_disabled" {
  description = "Risk behavior keys to leave disabled; every other predefined behavior is enabled"
  type        = list(string)
  default     = []
}

# 3.5 DLP
variable "dlp_financial_profile_id" {
  description = "ID of the predefined Financial Information DLP profile in this account"
  type        = string
}

variable "dlp_action" {
  description = "Action for the DLP policy: allow (log only while tuning) or block"
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.dlp_action)
    error_message = "dlp_action must be allow or block."
  }
}

# 4.1 WARP client (default device profile)
variable "warp_auto_connect_seconds" {
  description = "Seconds before a switched-off client reconnects: the guide's 1-15 minute Timeout. Keep a stricter current value rather than raising it"
  type        = number
  default     = 900

  validation {
    condition     = var.warp_auto_connect_seconds >= 60 && var.warp_auto_connect_seconds <= 900
    error_message = "warp_auto_connect_seconds must be 60-900 (1-15 minutes); 0 lets a switched-off client stay off indefinitely."
  }
}

variable "warp_captive_portal_seconds" {
  description = "Seconds allowed for captive-portal login (captive portal detection enabled)"
  type        = number
  default     = 180

  validation {
    condition     = var.warp_captive_portal_seconds > 0
    error_message = "warp_captive_portal_seconds must be greater than 0 (captive portal detection enabled)."
  }
}

# 5.1 Tunnel
variable "app_domain" {
  description = "Public hostname published through the tunnel (5.1) and protected by Access (5.2)"
  type        = string
}

variable "app_subdomain" {
  description = "DNS record name for the tunnel CNAME"
  type        = string
}

variable "app_origin_url" {
  description = "Origin service behind the tunnel, e.g. http://localhost:8080"
  type        = string
}

# 6.1 Logpush
variable "logpush_destination" {
  description = "Logpush destination_conf, e.g. s3://bucket/path?region=us-east-1"
  type        = string
}

variable "logpush_ownership_challenge" {
  description = "Ownership challenge token proving control of the destination"
  type        = string
  sensitive   = true
}
