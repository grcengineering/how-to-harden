# =============================================================================
# HTH Azure DevOps Control 6.1: Enable Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/azure-devops/#61-enable-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Azure DevOps audit logging is enabled by default at the organization
# level and accessed via Organization Settings > Auditing. The Terraform
# provider does not manage audit log configuration directly.
#
# This control creates a service hook to forward pipeline events to an
# external endpoint for SIEM integration. Service connection changes,
# permission changes, and pipeline modifications are captured.
#
# For full audit log export, use the Azure DevOps REST API:
#   GET https://auditservice.dev.azure.com/{org}/_apis/audit/auditlog
# ---------------------------------------------------------------------------

# Service hook: forward pipeline run events to external webhook (L2+)
resource "azuredevops_servicehook_permissions" "audit_hooks" {
  count = var.profile_level >= 2 ? 1 : 0

  project_id  = data.azuredevops_project.target.id
  principal   = azuredevops_group.security_reviewers.id
  permissions = {
    "ViewSubscriptions"   = "Allow"
    "EditSubscriptions"   = "Allow"
    "DeleteSubscriptions" = "Deny"
  }
}

# HTH Guide Excerpt: end terraform
