# HTH Pack Contract: v1
#   control: google-vertex-ai-1.1
#   guide: https://howtoharden.com/guides/google-vertex-ai/#11-allow-only-approved-model-garden-model-actions
#   profile: L1
#   mode: mutating
#   requires: Google Cloud CLI or Google Terraform provider, target-scoped IAM access
# HTH Google Vertex AI 1.1: Stage a Model Garden policy in dry-run
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/google-vertex-ai/
# Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy
# Start in a dedicated test project. Never create this over existing managed
# state: import/reconcile the policy and retain existing enforce/condition rules.
# HTH Guide Excerpt: begin stage-model-allowlist
variable "vertex_policy_project_number" {
  type = string
  validation {
    condition     = can(regex("^[0-9]+$", var.vertex_policy_project_number))
    error_message = "Provide an explicit Google Cloud project number."
  }
}

variable "vertex_approved_model_actions" {
  type = set(string)
  validation {
    condition = (
      length(var.vertex_approved_model_actions) > 0 &&
      length(var.vertex_approved_model_actions) <= 500 &&
      alltrue([
        for entry in var.vertex_approved_model_actions :
        can(regex("^publishers/[A-Za-z0-9._-]+/models/[A-Za-z0-9._-]+:(predict|deploy|tune)$", entry))
      ])
    )
    error_message = "Enter 1–500 exact publisher/model/action entries, without wildcards."
  }
}

resource "google_org_policy_policy" "vertex_model_allowlist" {
  name   = "projects/${var.vertex_policy_project_number}/policies/vertexai.allowedModels"
  parent = "projects/${var.vertex_policy_project_number}"

  dry_run_spec {
    inherit_from_parent = true
    rules {
      values {
        allowed_values = sort(tolist(var.vertex_approved_model_actions))
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
# HTH Guide Excerpt: end stage-model-allowlist
