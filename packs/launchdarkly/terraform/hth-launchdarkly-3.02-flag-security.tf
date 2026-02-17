# HTH LaunchDarkly Control 3.2: Flag Security
# Profile: L2 | NIST: CM-7
# https://howtoharden.com/guides/launchdarkly/#32-flag-security

terraform {
  required_providers {
    launchdarkly = {
      source  = "launchdarkly/launchdarkly"
      version = "~> 2.0"
    }
  }
}

# HTH Guide Excerpt: begin terraform
# Example: Secure feature flag with restricted client-side exposure
resource "launchdarkly_feature_flag" "secure_flag_example" {
  project_key    = var.project_key
  key            = "hth-example-secure-flag"
  name           = "HTH Example Secure Flag"
  description    = "Demonstrates HTH flag security best practices"
  variation_type = "boolean"
  temporary      = true

  # Restrict client-side SDK exposure
  client_side_availability {
    using_environment_id = false
    using_mobile_key     = false
  }

  # Assign a team maintainer for lifecycle ownership
  maintainer_team_key = var.maintainer_team_key

  tags = ["sensitive", "hth-managed"]

  variations {
    value       = true
    name        = "Enabled"
    description = "Feature is active"
  }

  variations {
    value       = false
    name        = "Disabled"
    description = "Feature is inactive"
  }

  defaults {
    on_variation  = 0
    off_variation = 1
  }
}
# HTH Guide Excerpt: end terraform

variable "project_key" {
  description = "LaunchDarkly project key"
  type        = string
}

variable "maintainer_team_key" {
  description = "Team key for flag ownership"
  type        = string
  default     = "platform-team"
}
