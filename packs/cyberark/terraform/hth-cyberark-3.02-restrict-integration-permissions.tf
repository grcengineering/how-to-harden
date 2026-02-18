# =============================================================================
# HTH CyberArk Control 3.2: Restrict Integration Permissions
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6
# Source: https://howtoharden.com/guides/cyberark/#32-restrict-integration-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create purpose-specific integration service accounts with least privilege
resource "null_resource" "integration_service_accounts" {
  for_each = var.integration_users

  provisioner "local-exec" {
    command = <<-EOT
      # Create the integration user
      curl -sk -X POST \
        "${var.pvwa_url}/PasswordVault/API/Users" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "username": "${each.key}",
          "userType": "ServiceAccount",
          "description": "Integration service account - least privilege",
          "enableUser": true,
          "authenticationMethod": ["CyberArk"]
        }'
    EOT
  }

  triggers = {
    user_name = each.key
  }
}

# Grant integration users access to specific safes only
resource "null_resource" "integration_safe_access" {
  for_each = var.integration_users

  provisioner "local-exec" {
    command = <<-EOT
      for SAFE in ${join(" ", each.value.safe_access)}; do
        curl -sk -X POST \
          "${var.pvwa_url}/PasswordVault/API/Safes/$SAFE/Members" \
          -H "Authorization: ${var.pvwa_auth_token}" \
          -H "Content-Type: application/json" \
          -d '{
            "memberName": "${each.key}",
            "memberType": "User",
            "permissions": {
              "useAccounts": ${each.value.use_accounts},
              "retrieveAccounts": ${each.value.retrieve},
              "listAccounts": ${each.value.list_accounts},
              "addAccounts": false,
              "updateAccountContent": false,
              "deleteAccounts": false,
              "manageSafe": false,
              "manageSafeMembers": false
            }
          }'
      done
    EOT
  }

  depends_on = [null_resource.integration_service_accounts]

  triggers = {
    user_name   = each.key
    safe_access = jsonencode(each.value.safe_access)
    permissions = jsonencode(each.value)
  }
}

# L2+: Enable audit logging for all integration account actions
resource "null_resource" "integration_audit_enforcement" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/AuditSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "auditServiceAccountActions": true,
            "detailedIntegrationLogging": true,
            "logRetrievalEvents": true,
            "logConnectionEvents": true
          }
        }'
    EOT
  }

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
