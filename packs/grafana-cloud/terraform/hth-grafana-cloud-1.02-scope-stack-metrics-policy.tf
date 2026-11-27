# HTH Pack Contract: v1
#   control: grafana-cloud-1.2
#   guide: https://howtoharden.com/guides/grafana-cloud/#12-scope-cloud-access-policies-by-stack-and-task
#   profile: L1
#   mode: mutating
#   requires: Terraform, Grafana provider 4.55.0, authorized GRAFANA_CLOUD_ACCESS_POLICY_TOKEN, region, stack_id
# Grafana Cloud 1.2 | L1 | NIST AC-6 | https://howtoharden.com/guides/grafana-cloud/#12-scope-cloud-access-policies-by-stack-and-task
# Review the plan before applying. This creates a policy but no credential.
# https://raw.githubusercontent.com/grafana/terraform-provider-grafana/v4.55.0/docs/resources/cloud_access_policy.md
# HTH Guide Excerpt: begin scope-grafana-stack-metrics-policy
terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "4.55.0"
    }
  }
}

# Authenticate with GRAFANA_CLOUD_ACCESS_POLICY_TOKEN; do not put it in this file.
provider "grafana" {}

variable "stack_id" {
  type        = string
  description = "Existing authorized Grafana Cloud stack ID."
}

variable "region" {
  type        = string
  description = "Exact region returned for the selected Grafana Cloud stack."
}

resource "grafana_cloud_access_policy" "stack_metrics_reader" {
  region = var.region
  name   = "stack-metrics-reader"
  scopes = ["metrics:read"]

  realm {
    type       = "stack"
    identifier = var.stack_id
  }
}
# HTH Guide Excerpt: end scope-grafana-stack-metrics-policy
