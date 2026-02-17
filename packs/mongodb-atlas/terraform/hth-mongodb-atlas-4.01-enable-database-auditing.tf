# =============================================================================
# MongoDB Atlas Hardening Code Pack - 4.1 Enable Database Auditing (L1)
# How to Harden (howtoharden.com)
#
# Enables database auditing to capture authentication events, CRUD operations,
# and administrative actions. Audit logs are critical for incident response,
# compliance evidence (SOC 2 CC7.2, NIST AU-2/AU-3), and detecting
# unauthorized access patterns.
#
# Requires M10+ dedicated clusters (not available on shared/free tier).
#
# See: https://howtoharden.com/guides/mongodb-atlas/#41-database-auditing
# API: https://www.mongodb.com/docs/atlas/reference/api-resources-spec/v2/
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.0"
    }
  }
}

provider "mongodbatlas" {
  public_key  = var.atlas_public_key
  private_key = var.atlas_private_key
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "atlas_public_key" {
  description = "MongoDB Atlas API public key"
  type        = string
}

variable "atlas_private_key" {
  description = "MongoDB Atlas API private key"
  type        = string
  sensitive   = true
}

variable "atlas_project_id" {
  description = "MongoDB Atlas project (group) ID"
  type        = string
}

variable "audit_filter" {
  description = "JSON audit filter expression (controls which events are logged)"
  type        = string
  default     = <<-EOT
    {
      "$or": [
        { "users": [] },
        { "atype": { "$in": [
          "authCheck", "authenticate", "createCollection",
          "createDatabase", "createIndex", "dropCollection",
          "dropDatabase", "dropIndex", "createUser", "dropUser",
          "updateUser", "grantRolesToUser", "revokeRolesFromUser",
          "createRole", "dropRole", "updateRole", "shutdown"
        ]}}
      ]
    }
  EOT
}

variable "audit_authorization_success" {
  description = "Log successful authorization checks (increases log volume, recommended for L2+)"
  type        = bool
  default     = false
}

# HTH Guide Excerpt: begin terraform
# -----------------------------------------------------------------------------
# 4.1 Database Auditing
# Captures authentication, authorization, and DDL events. The audit filter
# controls which operations are logged. Enable audit_authorization_success
# at L2+ for full authorization visibility (higher log volume).
# -----------------------------------------------------------------------------

resource "mongodbatlas_auditing" "config" {
  project_id                  = var.atlas_project_id
  audit_filter                = var.audit_filter
  audit_authorization_success = var.audit_authorization_success
  enabled                     = true
}
# HTH Guide Excerpt: end terraform

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "auditing_enabled" {
  description = "Whether database auditing is enabled"
  value       = mongodbatlas_auditing.config.enabled
}

output "auditing_filter" {
  description = "Active audit filter expression"
  value       = mongodbatlas_auditing.config.audit_filter
}
