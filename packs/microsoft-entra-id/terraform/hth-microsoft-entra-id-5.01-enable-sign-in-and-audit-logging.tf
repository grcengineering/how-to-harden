# =============================================================================
# HTH Microsoft Entra ID Control 5.1: Enable Sign-In and Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2/AU-3/AU-6
# Source: https://howtoharden.com/guides/microsoft-entra-id/#51-enable-sign-in-and-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure diagnostic settings to export Entra ID sign-in and audit logs.
#
# NOTE: Diagnostic settings for Entra ID require the Azure Monitor provider
# (azurerm), not the AzureAD provider. This control documents the configuration
# and provides a reference implementation. If you are also managing Azure
# resources, add the azurerm provider to providers.tf and uncomment below.
#
# Uncomment and configure when using the azurerm provider:
#
# resource "azurerm_monitor_aad_diagnostic_setting" "entra_id_logs" {
#   name                       = "hth-entra-id-logging"
#   log_analytics_workspace_id = var.log_analytics_workspace_id
#
#   enabled_log {
#     category = "SignInLogs"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
#
#   enabled_log {
#     category = "AuditLogs"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
#
#   enabled_log {
#     category = "NonInteractiveUserSignInLogs"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
#
#   enabled_log {
#     category = "ServicePrincipalSignInLogs"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
#
#   enabled_log {
#     category = "ManagedIdentitySignInLogs"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
#
#   enabled_log {
#     category = "RiskyUsers"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
#
#   enabled_log {
#     category = "UserRiskEvents"
#     retention_policy {
#       enabled = true
#       days    = 90
#     }
#   }
# }

locals {
  logging_config = {
    status                   = var.log_analytics_workspace_id != "" ? "REQUIRES_AZURERM_PROVIDER" : "NOT_CONFIGURED"
    workspace_id             = var.log_analytics_workspace_id
    recommended_log_categories = [
      "SignInLogs",
      "AuditLogs",
      "NonInteractiveUserSignInLogs",
      "ServicePrincipalSignInLogs",
      "ManagedIdentitySignInLogs",
      "RiskyUsers",
      "UserRiskEvents",
    ]
    recommended_retention_days = 90
    instructions = var.log_analytics_workspace_id != "" ? "Add azurerm provider and uncomment the diagnostic setting resource" : "Set log_analytics_workspace_id variable and add azurerm provider"
    alert_rules = [
      "Global Admin role assignment",
      "Conditional Access policy changes",
      "New OAuth app registration",
      "Risky sign-in detected",
      "Emergency account sign-in",
    ]
  }
}
# HTH Guide Excerpt: end terraform
