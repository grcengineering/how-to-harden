# HTH LaunchDarkly Control 4.1: Audit Log
# Profile: L1 | NIST: AU-2, AU-3
# https://howtoharden.com/guides/launchdarkly/#41-audit-log

terraform {
  required_providers {
    launchdarkly = {
      source  = "launchdarkly/launchdarkly"
      version = "~> 2.0"
    }
  }
}

# HTH Guide Excerpt: begin terraform
# Splunk audit log subscription
resource "launchdarkly_audit_log_subscription" "splunk" {
  integration_key = "splunk"
  name            = "HTH Splunk Audit Stream"
  on              = true

  config = {
    base_url = var.splunk_hec_url
    token    = var.splunk_hec_token
  }

  statements {
    effect    = "allow"
    actions   = ["*"]
    resources = ["proj/*"]
  }

  tags = ["hth", "siem"]
}

# Signed webhook for custom SIEM
resource "launchdarkly_webhook" "siem" {
  name   = "HTH SIEM Webhook"
  url    = var.siem_webhook_url
  on     = true
  secret = var.webhook_signing_secret

  statements {
    effect    = "allow"
    actions   = ["*"]
    resources = ["proj/*"]
  }

  tags = ["hth", "siem"]
}
# HTH Guide Excerpt: end terraform

variable "splunk_hec_url" {
  description = "Splunk HTTP Event Collector URL"
  type        = string
  default     = "https://http-inputs.splunk.example.com"
}

variable "splunk_hec_token" {
  description = "Splunk HEC token"
  type        = string
  sensitive   = true
}

variable "siem_webhook_url" {
  description = "SIEM webhook endpoint URL"
  type        = string
}

variable "webhook_signing_secret" {
  description = "HMAC-SHA256 signing secret for webhook"
  type        = string
  sensitive   = true
}
