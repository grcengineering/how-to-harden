# =============================================================================
# HTH Azure DevOps Control 2.3: Implement Service Connection Approval Gates
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/azure-devops/#23-implement-service-connection-approval-gates
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Require approval before pipelines can use sensitive service connections.
# This applies check_approval and check_branch_control to the workload
# identity service connection. Only created at L2+ profile levels.
# ---------------------------------------------------------------------------

# Approval gate: require security team sign-off before service connection use
resource "azuredevops_check_approval" "service_connection_approval" {
  count = var.profile_level >= 2 && var.azure_subscription_id != "" ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.workload_identity[0].id
  target_resource_type = "endpoint"

  requester_can_approve = false
  approvers             = var.service_connection_approvers
}

# Branch control: only allow service connection use from protected branches
resource "azuredevops_check_branch_control" "service_connection_branch" {
  count = var.profile_level >= 2 && var.azure_subscription_id != "" ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.workload_identity[0].id
  target_resource_type = "endpoint"

  display_name                = "Branch Control - Protected Branches Only"
  allowed_branches            = "refs/heads/main,refs/heads/release/*"
  verify_branch_protection    = true
  ignore_unknown_protection_status = false
}

# Business hours check: restrict production deployments to business hours (L3)
resource "azuredevops_check_business_hours" "service_connection_hours" {
  count = var.profile_level >= 3 && var.azure_subscription_id != "" ? 1 : 0

  project_id           = data.azuredevops_project.target.id
  target_resource_id   = azuredevops_serviceendpoint_azurerm.workload_identity[0].id
  target_resource_type = "endpoint"

  display_name = "Business Hours - Weekdays 09:00-17:00 UTC"
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

# HTH Guide Excerpt: end terraform
