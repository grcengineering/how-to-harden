# =============================================================================
# HTH Pack Contract: v1
#   control: langchain-5.3
#   guide:   https://howtoharden.com/guides/langchain/#53-restrict-trace-project-access
#   profile: L2
#   mode:    mutating
#   requires: LANGSMITH_API_KEY(organization-scoped service key with Organization Admin; Enterprise plan for ABAC), LANGSMITH_WORKSPACE_ID(workspace that holds the tracing project; tags are workspace-scoped)
#
# HTH LangChain Control 5.3: Restrict Trace Project Access
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AC-3 | SOC 2 CC6.3
#
# PROVIDER BLOCK LIVES IN hth-langchain-1.2-service-key.tf. Uses the Auditor role from
# hth-langchain-1.3-custom-roles.tf.
#
# ABAC (https://docs.langchain.com/langsmith/abac): tags live on resources, policies
# match on `resource_tag_key`, deny always beats allow, and policies are managed by API
# or Terraform only (the vendor documents no console for them).
# Official provider langchain-ai/langsmith 0.0.16 (schema checked 2026-09-24):
#   langsmith_tag, langsmith_tagging, langsmith_access_policy,
#   langsmith_access_policy_attachment; data langsmith_project (name -> id)
# =============================================================================

# HTH Guide Excerpt: begin terraform-restrict-pii-projects
variable "pii_project_name" {
  description = "Name of the tracing project whose traces carry PII"
  type        = string
}

data "langsmith_project" "pii" {
  name = var.pii_project_name
}

# Tag the PII-bearing tracing project: data-class=pii
resource "langsmith_tag" "data_class_pii" {
  key               = "data-class"
  value             = "pii"
  key_description   = "Data classification"
  value_description = "Projects whose traces carry PII"
}

resource "langsmith_tagging" "pii_project" {
  tag_value_id  = langsmith_tag.data_class_pii.tag_value_id
  resource_type = "project"
  resource_id   = data.langsmith_project.pii.id
}

# Deny reading PII-tagged projects (and their runs) to the Auditor role
resource "langsmith_access_policy" "deny_pii_projects" {
  name        = "Deny PII projects"
  description = "Roles attached here may not read projects tagged data-class=pii"
  effect      = "deny"
  condition_groups = [
    for perm in ["projects:read", "runs:read"] : {
      permission    = perm
      resource_type = "project"
      conditions = [{
        attribute_name  = "resource_tag_key"
        attribute_key   = "data-class"
        operator        = "equals"
        attribute_value = "pii"
      }]
    }
  ]
}

resource "langsmith_access_policy_attachment" "auditor_deny_pii" {
  role_id          = langsmith_workspace_role.auditor.id
  access_policy_id = langsmith_access_policy.deny_pii_projects.id
}
# HTH Guide Excerpt: end terraform-restrict-pii-projects
