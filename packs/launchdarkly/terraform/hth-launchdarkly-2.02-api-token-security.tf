# HTH LaunchDarkly Control 2.2: API Token Security
# Profile: L1 | NIST: IA-5
# https://howtoharden.com/guides/launchdarkly/#22-api-token-security

terraform {
  required_providers {
    launchdarkly = {
      source  = "launchdarkly/launchdarkly"
      version = "~> 2.0"
    }
  }
}

# HTH Guide Excerpt: begin terraform
# Scoped read-only token for monitoring
resource "launchdarkly_access_token" "monitoring" {
  name          = "HTH Monitoring Read-Only"
  service_token = true

  inline_roles {
    effect    = "allow"
    actions   = ["viewProject"]
    resources = ["proj/*"]
  }

  inline_roles {
    effect    = "deny"
    actions   = ["createFlag", "deleteFlag", "updateOn", "updateOff"]
    resources = ["proj/*:env/*:flag/*"]
  }
}

# Scoped token for a specific project/environment
resource "launchdarkly_access_token" "project_scoped" {
  name          = "HTH Project-Scoped Token"
  service_token = true

  inline_roles {
    effect    = "allow"
    actions   = ["viewProject", "updateOn", "updateOff"]
    resources = ["proj/${var.project_key}:env/${var.environment_key}:flag/*"]
  }
}
# HTH Guide Excerpt: end terraform

variable "project_key" {
  description = "LaunchDarkly project key"
  type        = string
}

variable "environment_key" {
  description = "LaunchDarkly environment key"
  type        = string
  default     = "staging"
}
