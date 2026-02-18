# =============================================================================
# HTH Azure DevOps Control 3.2: Configure Pipeline Permissions and Approvals
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3
# Source: https://howtoharden.com/guides/azure-devops/#32-configure-pipeline-permissions-and-approvals
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Create deployment environments with approval gates. Production
# environments require approval before pipeline deployment jobs can
# proceed. Staging environments are created without approval for L1,
# with approval added at L2+.
# ---------------------------------------------------------------------------

# Production environment with mandatory approval
resource "azuredevops_environment" "production" {
  project_id  = data.azuredevops_project.target.id
  name        = var.production_environment_name
  description = "Production deployment environment - requires approval"
}

# Staging environment
resource "azuredevops_environment" "staging" {
  project_id  = data.azuredevops_project.target.id
  name        = var.staging_environment_name
  description = "Staging deployment environment"
}

# Approval gate for production environment
resource "azuredevops_check_approval" "production_approval" {
  count = length(var.deployment_approvers) > 0 ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_environment.production.id
  target_resource_type = "environment"

  requester_can_approve = false
  approvers             = var.deployment_approvers
}

# Branch control for production: only deploy from main branch
resource "azuredevops_check_branch_control" "production_branch" {
  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_environment.production.id
  target_resource_type = "environment"

  display_name                = "Branch Control - Main Branch Only"
  allowed_branches            = "refs/heads/main"
  verify_branch_protection    = true
  ignore_unknown_protection_status = false
}

# Business hours restriction for production (L3)
resource "azuredevops_check_business_hours" "production_hours" {
  count = var.profile_level >= 3 ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_environment.production.id
  target_resource_type = "environment"

  display_name = "Business Hours - Production Deployments Only"
  time_zone    = "UTC"

  monday {
    start_time = "09:00"
    end_time   = "17:00"
  }
  tuesday {
    start_time = "09:00"
    end_time   = "17:00"
  }
  wednesday {
    start_time = "09:00"
    end_time   = "17:00"
  }
  thursday {
    start_time = "09:00"
    end_time   = "17:00"
  }
  friday {
    start_time = "09:00"
    end_time   = "17:00"
  }
}

# Exclusive lock for production deployments (L2+) -- prevent concurrent deploys
resource "azuredevops_check_exclusive_lock" "production_lock" {
  count = var.profile_level >= 2 ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_environment.production.id
  target_resource_type = "environment"
}

# HTH Guide Excerpt: end terraform
