# =============================================================================
# HTH HashiCorp Vault Control 4.1: Enable Comprehensive Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3, AU-6, AU-12 | SOC 2 CC7.2 | ISO 27001 A.12.4.1
# Source: https://howtoharden.com/guides/hashicorp-vault/#41-enable-comprehensive-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# --- File audit device (local persistent log) ---
resource "vault_audit" "file" {
  type        = "file"
  path        = "file"
  description = "File-based audit log for local retention"

  options = {
    file_path = var.audit_file_path
    log_raw   = "false"
    hmac_accessor = "true"
    mode      = "0600"
  }
}

# --- Syslog audit device (centralized log forwarding) ---
resource "vault_audit" "syslog" {
  type        = "syslog"
  path        = "syslog"
  description = "Syslog audit device for SIEM integration"

  options = {
    tag      = "vault-audit"
    facility = "AUTH"
    log_raw  = "false"
  }
}

# --- Socket audit device (real-time log streaming, L2+) ---
resource "vault_audit" "socket" {
  count       = var.profile_level >= 2 ? 1 : 0
  type        = "socket"
  path        = "socket"
  description = "Socket audit device for real-time log streaming"

  options = {
    address     = var.audit_socket_address
    socket_type = "tcp"
    log_raw     = "false"
  }
}
# HTH Guide Excerpt: end terraform

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "profile_level" {
  description = "Hardening profile level: 1 = Baseline, 2 = Hardened, 3 = Maximum Security"
  type        = number
  default     = 1

  validation {
    condition     = var.profile_level >= 1 && var.profile_level <= 3
    error_message = "Profile level must be 1, 2, or 3."
  }
}

variable "audit_file_path" {
  description = "File path for the file audit device log output"
  type        = string
  default     = "/var/log/vault/audit.log"
}

variable "audit_socket_address" {
  description = "Socket address for real-time audit log streaming (L2+)"
  type        = string
  default     = "127.0.0.1:9090"
}
