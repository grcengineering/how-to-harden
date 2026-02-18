# =============================================================================
# HTH Azure DevOps Control 2.2: Audit and Rotate Legacy Service Connections
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(1)
# Source: https://howtoharden.com/guides/azure-devops/#22-audit-and-rotate-legacy-service-connections
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Legacy service connection auditing and rotation cannot be fully automated
# via Terraform. This data source retrieves all service endpoints in the
# project so they can be reviewed and output for audit purposes.
#
# Rotation workflow:
#   1. Generate new credentials in the target service
#   2. Update the service connection (manual or API)
#   3. Verify pipeline functionality
#   4. Revoke old credentials
# ---------------------------------------------------------------------------

data "azuredevops_serviceendpoint_azurerm" "existing" {
  for_each = toset(var.legacy_service_connection_ids)

  project_id            = data.azuredevops_project.target.id
  service_endpoint_id   = each.value
}

# HTH Guide Excerpt: end terraform
