# =============================================================================
# MongoDB Atlas Hardening Code Pack - 1.1 Configure IP Access List (L1)
# How to Harden (howtoharden.com)
#
# Restricts network access to the Atlas project by defining an explicit IP
# access list. Only connections from approved CIDR blocks can reach databases.
# Prevents open-internet exposure (0.0.0.0/0) which is the most common Atlas
# misconfiguration.
#
# See: https://howtoharden.com/guides/mongodb-atlas/#11-ip-access-list
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

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks to allow in the project IP access list"
  type = list(object({
    cidr_block = string
    comment    = string
  }))
  default = []

  validation {
    condition     = length(var.allowed_cidr_blocks) > 0
    error_message = "At least one CIDR block must be specified. Never use 0.0.0.0/0."
  }
}

# HTH Guide Excerpt: begin terraform
# -----------------------------------------------------------------------------
# 1.1 IP Access List Entries
# Each entry restricts database connections to an approved CIDR range.
# NEVER include 0.0.0.0/0 -- this opens databases to the entire internet.
# -----------------------------------------------------------------------------

resource "mongodbatlas_project_ip_access_list" "allowed" {
  for_each = { for idx, entry in var.allowed_cidr_blocks : idx => entry }

  project_id = var.atlas_project_id
  cidr_block = each.value.cidr_block
  comment    = each.value.comment
}
# HTH Guide Excerpt: end terraform

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "ip_access_list_entries" {
  description = "Configured IP access list entries"
  value = {
    for k, v in mongodbatlas_project_ip_access_list.allowed :
    k => {
      cidr_block = v.cidr_block
      comment    = v.comment
    }
  }
}
