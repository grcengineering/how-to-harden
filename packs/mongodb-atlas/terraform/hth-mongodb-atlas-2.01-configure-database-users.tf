# =============================================================================
# MongoDB Atlas Hardening Code Pack - 2.1 Configure Database Users (L1)
# How to Harden (howtoharden.com)
#
# Creates database users with scoped roles following least-privilege principles.
# Avoids granting atlasAdmin or readWriteAnyDatabase across all databases.
# Each user should be scoped to specific databases and collections.
#
# See: https://howtoharden.com/guides/mongodb-atlas/#21-database-users
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

variable "database_users" {
  description = "List of database users with scoped roles (least-privilege)"
  type = list(object({
    username      = string
    password      = string
    auth_database = string
    roles = list(object({
      role_name       = string
      database_name   = string
      collection_name = optional(string, "")
    }))
    scopes = optional(list(object({
      name = string
      type = string
    })), [])
  }))
  default   = []
  sensitive = true
}

# HTH Guide Excerpt: begin terraform
# -----------------------------------------------------------------------------
# 2.1 Database Users with Scoped Roles
# Each user receives only the minimum permissions needed. Roles are scoped
# to specific databases rather than granted project-wide. Avoid atlasAdmin
# and readWriteAnyDatabase unless absolutely required and documented.
# -----------------------------------------------------------------------------

resource "mongodbatlas_database_user" "users" {
  for_each = { for idx, user in var.database_users : user.username => user }

  project_id         = var.atlas_project_id
  username           = each.value.username
  password           = each.value.password
  auth_database_name = each.value.auth_database

  dynamic "roles" {
    for_each = each.value.roles
    content {
      role_name       = roles.value.role_name
      database_name   = roles.value.database_name
      collection_name = roles.value.collection_name
    }
  }

  dynamic "scopes" {
    for_each = each.value.scopes
    content {
      name = scopes.value.name
      type = scopes.value.type
    }
  }
}
# HTH Guide Excerpt: end terraform

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "database_users_created" {
  description = "Database users created with their role assignments"
  value = {
    for k, v in mongodbatlas_database_user.users :
    k => {
      username      = v.username
      auth_database = v.auth_database_name
      role_count    = length(v.roles)
    }
  }
}
