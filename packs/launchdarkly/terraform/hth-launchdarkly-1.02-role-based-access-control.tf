# HTH LaunchDarkly Control 1.2: Role-Based Access Control
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/launchdarkly/#12-role-based-access-control
#
# NOTE: Control 1.1 (SSO/MFA) has no Terraform resource — GUI-only configuration.

terraform {
  required_providers {
    launchdarkly = {
      source  = "launchdarkly/launchdarkly"
      version = "~> 2.0"
    }
  }
}

# HTH Guide Excerpt: begin terraform
# Production read-only role — least-privilege RBAC
resource "launchdarkly_custom_role" "prod_readonly" {
  key              = "hth-prod-readonly"
  name             = "HTH Production Read-Only"
  description      = "View production flags without modification rights"
  base_permissions = "no_access"

  policy_statements {
    effect    = "allow"
    actions   = ["viewProject"]
    resources = ["proj/*"]
  }

  policy_statements {
    effect    = "deny"
    actions   = ["updateOn", "updateOff", "updateRules", "updateTargets", "updateFallthrough"]
    resources = ["proj/*:env/production:flag/*"]
  }
}

# Staging deployer role — write flags in staging only
resource "launchdarkly_custom_role" "staging_deployer" {
  key              = "hth-staging-deployer"
  name             = "HTH Staging Deployer"
  description      = "Manage flags in staging, read-only in production"
  base_permissions = "no_access"

  policy_statements {
    effect    = "allow"
    actions   = ["viewProject"]
    resources = ["proj/*"]
  }

  policy_statements {
    effect    = "allow"
    actions   = ["*"]
    resources = ["proj/*:env/staging:flag/*"]
  }

  policy_statements {
    effect    = "deny"
    actions   = ["*"]
    resources = ["proj/*:env/production:flag/*"]
  }
}

# Scoped service token for CI/CD
resource "launchdarkly_access_token" "cicd" {
  name          = "HTH CI/CD Pipeline"
  service_token = true

  inline_roles {
    effect    = "allow"
    actions   = ["updateOn", "updateOff"]
    resources = ["proj/${var.project_key}:env/staging:flag/*"]
  }

  inline_roles {
    effect    = "deny"
    actions   = ["*"]
    resources = ["proj/${var.project_key}:env/production:flag/*"]
  }
}
# HTH Guide Excerpt: end terraform

variable "project_key" {
  description = "LaunchDarkly project key"
  type        = string
}
