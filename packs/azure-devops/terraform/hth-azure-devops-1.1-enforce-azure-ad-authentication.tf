# =============================================================================
# HTH Azure DevOps Control 1.1: Enforce Azure AD Authentication with Conditional Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1), SOC 2 CC6.1
# Source: https://howtoharden.com/guides/azure-devops/#11-enforce-azure-ad-authentication-with-conditional-access
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Disable alternate authentication methods at the project level.
# Azure AD connection and Conditional Access policies are configured in
# the Azure Portal (Entra ID) -- not via the Azure DevOps provider.
# This resource restricts project pipeline settings that weaken auth posture.
# ---------------------------------------------------------------------------

resource "azuredevops_project_features" "auth_hardening" {
  project_id = data.azuredevops_project.target.id

  features = {
    # Disable features that are not required to reduce attack surface
    "artifacts"    = "disabled"
    "testplans"    = "disabled"
    "boards"       = "enabled"
    "repositories" = "enabled"
    "pipelines"    = "enabled"
  }
}

# Look up the target project by name
data "azuredevops_project" "target" {
  name = var.project_name
}

# HTH Guide Excerpt: end terraform
