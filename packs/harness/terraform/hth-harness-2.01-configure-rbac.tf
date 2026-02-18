# =============================================================================
# HTH Harness Control 2.1: Configure Role-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/harness/#21-configure-role-based-access-control
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Custom least-privilege roles for pipeline operators
resource "harness_platform_roles" "pipeline_executor" {
  identifier         = "hth_pipeline_executor"
  name               = "Pipeline Executor"
  description        = "Least-privilege role for executing pipelines without admin access (HTH Control 2.1)"
  permissions        = [
    "core_pipeline_view",
    "core_pipeline_execute",
    "core_service_view",
    "core_environment_view",
    "core_connector_view"
  ]
  allowed_scope_levels = ["project"]
}

# Read-only viewer role for auditors and observers
resource "harness_platform_roles" "viewer" {
  identifier         = "hth_viewer"
  name               = "Read-Only Viewer"
  description        = "Read-only role for auditors and observers (HTH Control 2.1)"
  permissions        = [
    "core_pipeline_view",
    "core_service_view",
    "core_environment_view",
    "core_connector_view",
    "core_secret_view"
  ]
  allowed_scope_levels = ["project"]
}

# Custom roles from variable input
resource "harness_platform_roles" "custom" {
  for_each = var.custom_roles

  identifier         = each.key
  name               = each.value.name
  description        = "Custom role managed by HTH Code Pack (Control 2.1)"
  permissions        = each.value.permissions
  allowed_scope_levels = each.value.allowed_scope_levels
}

# Resource group scoping pipeline resources at the project level
resource "harness_platform_resource_group" "project_pipelines" {
  identifier  = "hth_project_pipelines"
  name        = "Project Pipelines"
  description = "Resource group scoped to pipeline resources within a project (HTH Control 2.1)"
  account_id  = var.harness_account_id

  included_scopes {
    filter = "INCLUDING_CHILD_SCOPES"
  }

  resource_filter {
    include_all_resources = false

    resources {
      resource_type = "PIPELINE"
    }

    resources {
      resource_type = "SERVICE"
    }

    resources {
      resource_type = "ENVIRONMENT"
    }
  }
}
# HTH Guide Excerpt: end terraform
