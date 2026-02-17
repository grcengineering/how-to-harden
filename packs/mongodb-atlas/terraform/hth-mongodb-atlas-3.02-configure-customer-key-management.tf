# =============================================================================
# MongoDB Atlas Hardening Code Pack - 3.2 Configure Customer Key Management (L2)
# How to Harden (howtoharden.com)
#
# Enables encryption at rest using a customer-managed key (CMK) via AWS KMS.
# Atlas encrypts data at rest by default with MongoDB-managed keys, but L2
# requires customer control over the encryption key lifecycle for compliance
# with SOC 2 CC6.1 and NIST SC-12/SC-28.
#
# Supports AWS KMS, Azure Key Vault, and GCP KMS. This example uses AWS KMS.
#
# See: https://howtoharden.com/guides/mongodb-atlas/#32-customer-key-management
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

variable "aws_kms_key_id" {
  description = "AWS KMS key ARN for Atlas encryption at rest"
  type        = string
}

variable "aws_kms_region" {
  description = "AWS region where the KMS key resides"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS IAM access key ID with kms:Encrypt, kms:Decrypt permissions"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS IAM secret access key"
  type        = string
  sensitive   = true
}

variable "aws_role_arn" {
  description = "AWS IAM role ARN for Atlas to assume (alternative to access keys)"
  type        = string
  default     = ""
}

# HTH Guide Excerpt: begin terraform
# -----------------------------------------------------------------------------
# 3.2 Encryption at Rest with Customer-Managed Keys (AWS KMS)
# Enables customer-controlled encryption keys so the organization retains
# full control over the key lifecycle (rotation, revocation, audit).
# Atlas uses envelope encryption: the CMK wraps the data encryption key.
# -----------------------------------------------------------------------------

resource "mongodbatlas_encryption_at_rest" "cmk" {
  project_id = var.atlas_project_id

  aws_kms_config {
    enabled                = true
    customer_master_key_id = var.aws_kms_key_id
    region                 = var.aws_kms_region
    access_key_id          = var.aws_access_key_id
    secret_access_key      = var.aws_secret_access_key
    role_id                = var.aws_role_arn != "" ? var.aws_role_arn : null
  }
}
# HTH Guide Excerpt: end terraform

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "encryption_at_rest_enabled" {
  description = "Whether customer-managed encryption at rest is enabled"
  value       = mongodbatlas_encryption_at_rest.cmk.aws_kms_config[0].enabled
}

output "encryption_kms_region" {
  description = "AWS region of the KMS key used for encryption"
  value       = mongodbatlas_encryption_at_rest.cmk.aws_kms_config[0].region
}
