# HTH LaunchDarkly Control 3.1: Environment Segmentation
# Profile: L1 | NIST: CM-3
# https://howtoharden.com/guides/launchdarkly/#31-environment-segmentation

terraform {
  required_providers {
    launchdarkly = {
      source  = "launchdarkly/launchdarkly"
      version = "~> 2.0"
    }
  }
}

# HTH Guide Excerpt: begin terraform
# Hardened production environment with approval workflows
resource "launchdarkly_environment" "production" {
  key                  = "production"
  name                 = "Production"
  color                = "FF0000"
  project_key          = var.project_key
  require_comments     = true
  confirm_changes      = true
  secure_mode          = true
  critical             = true
  default_track_events = true

  approval_settings {
    required                   = true
    min_num_approvals          = 2
    can_review_own_request     = false
    can_apply_declined_changes = false
    required_approval_tags     = ["sensitive"]
    service_kind               = "launchdarkly"
  }

  tags = ["hth-hardened"]
}

# Staging environment — comments required, but no approval gate
resource "launchdarkly_environment" "staging" {
  key              = "staging"
  name             = "Staging"
  color            = "FFA500"
  project_key      = var.project_key
  require_comments = true
  confirm_changes  = true
  secure_mode      = false
  critical         = false
}
# HTH Guide Excerpt: end terraform

variable "project_key" {
  description = "LaunchDarkly project key"
  type        = string
}
