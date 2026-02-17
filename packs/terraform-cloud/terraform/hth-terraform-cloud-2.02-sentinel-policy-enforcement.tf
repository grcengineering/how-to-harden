# =============================================================================
# HTH Terraform Cloud Control 2.02: Sentinel Policy Enforcement
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7
# Source: https://howtoharden.com/guides/terraform-cloud/#22-sentinel-policy-enforcement
# =============================================================================

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62"
    }
  }
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "workspace_ids" {
  description = "List of workspace IDs to attach the policy set to"
  type        = list(string)
  default     = []
}

variable "sentinel_vcs_identifier" {
  description = "VCS repository containing Sentinel policies (e.g., org/sentinel-policies)"
  type        = string
  default     = ""
}

variable "sentinel_oauth_token_id" {
  description = "OAuth token ID for the Sentinel VCS repository"
  type        = string
  default     = ""
}

# HTH Guide Excerpt: begin terraform
# Sentinel policy: require encryption on S3 buckets
resource "tfe_sentinel_policy" "require_encryption" {
  name         = "require-s3-encryption"
  description  = "Require server-side encryption on all S3 buckets"
  organization = var.tfc_organization
  policy       = <<-SENTINEL
    import "tfplan/v2" as tfplan

    s3_buckets = filter tfplan.resource_changes as _, rc {
      rc.type is "aws_s3_bucket" and
      (rc.change.actions contains "create" or rc.change.actions contains "update")
    }

    encryption_enabled = rule {
      all s3_buckets as _, bucket {
        bucket.change.after.server_side_encryption_configuration is not null
      }
    }

    main = rule {
      encryption_enabled
    }
  SENTINEL
  enforce_mode = "hard-mandatory"
}

# Sentinel policy: deny public access
resource "tfe_sentinel_policy" "deny_public_access" {
  name         = "deny-public-access"
  description  = "Deny public access blocks being disabled on S3 buckets"
  organization = var.tfc_organization
  policy       = <<-SENTINEL
    import "tfplan/v2" as tfplan

    s3_public_access = filter tfplan.resource_changes as _, rc {
      rc.type is "aws_s3_bucket_public_access_block" and
      (rc.change.actions contains "create" or rc.change.actions contains "update")
    }

    all_blocked = rule {
      all s3_public_access as _, block {
        block.change.after.block_public_acls is true and
        block.change.after.block_public_policy is true and
        block.change.after.ignore_public_acls is true and
        block.change.after.restrict_public_buckets is true
      }
    }

    main = rule {
      all_blocked
    }
  SENTINEL
  enforce_mode = "hard-mandatory"
}

# Policy set: attach policies to workspaces via VCS or inline
resource "tfe_policy_set" "security_guardrails" {
  name          = "hth-security-guardrails"
  description   = "HTH security guardrails -- hard-mandatory enforcement"
  organization  = var.tfc_organization
  kind          = "sentinel"
  workspace_ids = var.workspace_ids

  # VCS-backed policy set (recommended for versioned policies)
  dynamic "vcs_repo" {
    for_each = var.sentinel_vcs_identifier != "" ? [1] : []
    content {
      identifier     = var.sentinel_vcs_identifier
      oauth_token_id = var.sentinel_oauth_token_id
      branch         = "main"
    }
  }
}

# Attach individual policies to the policy set
resource "tfe_policy_set_parameter" "encryption_policy" {
  policy_set_id = tfe_policy_set.security_guardrails.id
  key           = "require_encryption"
  value         = "true"
  category      = "sentinel"
}
# HTH Guide Excerpt: end terraform
