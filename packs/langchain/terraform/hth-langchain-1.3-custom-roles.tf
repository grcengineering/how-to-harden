# =============================================================================
# HTH Pack Contract: v1
#   control: langchain-1.3
#   guide:   https://howtoharden.com/guides/langchain/#13-enforce-rbac-and-abac-for-project--dataset-access
#   profile: L2
#   mode:    mutating
#   requires: LANGSMITH_API_KEY(Organization Admin service key; Enterprise plan for custom roles)
#
# HTH LangChain Control 1.3: Enforce RBAC and ABAC for Project / Dataset Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 6.8 | NIST 800-53 AC-3, AC-6
#
# PROVIDER BLOCK LIVES IN hth-langchain-1.2-service-key.tf.
#
# Official provider langchain-ai/langsmith 0.0.16 (schema checked 2026-09-24):
#   resource langsmith_workspace_role: display_name, description, permissions (all required)
#   data     langsmith_permissions:    permissions[] {name, access_scope, description}
# Permissions are `<resource>:<action>` strings (https://docs.langchain.com/langsmith/rbac,
# https://docs.langchain.com/langsmith/abac). Custom roles take workspace-level
# permissions only and apply across every workspace in the organization.
# The ABAC half of this control (tag-scoped deny policies) is the 5.3 Terraform pack.
# =============================================================================

# HTH Guide Excerpt: begin terraform-auditor-role
locals {
  auditor_permissions = ["projects:read", "runs:read", "datasets:read", "prompts:read"]
}

# Read side: the permission names this LangSmith instance actually accepts
data "langsmith_permissions" "all" {}

# Least-privilege, read-only custom role for SOC reviewers
resource "langsmith_workspace_role" "auditor" {
  display_name = "Auditor"
  description  = "Read-only reviewer: traces, runs, datasets and prompts"
  permissions  = local.auditor_permissions

  lifecycle {
    precondition {
      condition = alltrue([
        for p in local.auditor_permissions :
        contains([for x in data.langsmith_permissions.all.permissions : x.name], p)
      ])
      error_message = "An Auditor permission is not a valid LangSmith permission name."
    }
  }
}
# HTH Guide Excerpt: end terraform-auditor-role
