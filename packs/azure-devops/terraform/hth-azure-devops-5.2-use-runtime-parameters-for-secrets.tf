# =============================================================================
# HTH Azure DevOps Control 5.2: Use Runtime Parameters for Secrets
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/azure-devops/#52-use-runtime-parameters-for-secrets
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Runtime parameters are a YAML pipeline feature -- they cannot be
# configured via Terraform. This control enforces the project-level
# pipeline setting that restricts settable variables at queue time,
# ensuring that only explicitly declared parameters can be set.
#
# The enforce_settable_var setting prevents unauthorized variable
# injection during pipeline execution.
#
# NOTE: The actual runtime parameter YAML pattern is documented in the
# guide and implemented in pipeline definitions, not infrastructure code.
# ---------------------------------------------------------------------------

# Approval gate for variable group access (L2+)
resource "azuredevops_check_approval" "variable_group_approval" {
  count = var.profile_level >= 2 && var.key_vault_name != "" && length(var.deployment_approvers) > 0 ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_variable_group.production_secrets[0].id
  target_resource_type = "variablegroup"

  requester_can_approve = false
  approvers             = var.deployment_approvers
}

# HTH Guide Excerpt: end terraform
