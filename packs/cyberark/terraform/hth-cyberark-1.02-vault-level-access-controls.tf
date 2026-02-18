# =============================================================================
# HTH CyberArk Control 1.2: Implement Vault-Level Access Controls
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/cyberark/#12-implement-vault-level-access-controls
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create safes with granular access controls
resource "null_resource" "create_safes" {
  for_each = var.safes

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X POST \
        "${var.pvwa_url}/PasswordVault/API/Safes" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "safeName": "${each.key}",
          "description": "${each.value.description}",
          "olacEnabled": ${each.value.olac_enabled},
          "managingCPM": "${each.value.managing_cpm}",
          "numberOfVersionsRetention": ${each.value.retention_versions},
          "numberOfDaysRetention": ${each.value.retention_days}
        }'
    EOT
  }

  triggers = {
    safe_name   = each.key
    description = each.value.description
    olac        = each.value.olac_enabled
  }
}

# Add members to safes with least-privilege permissions
resource "null_resource" "safe_members" {
  for_each = var.safe_members

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X POST \
        "${var.pvwa_url}/PasswordVault/API/Safes/${each.value.safe_name}/Members" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "memberName": "${each.value.member_name}",
          "memberType": "${each.value.member_type}",
          "permissions": {
            "useAccounts": ${each.value.use_accounts},
            "retrieveAccounts": ${each.value.retrieve_accounts},
            "listAccounts": ${each.value.list_accounts},
            "addAccounts": ${each.value.add_accounts},
            "updateAccountContent": ${each.value.update_accounts},
            "deleteAccounts": ${each.value.delete_accounts},
            "manageSafe": ${each.value.manage_safe},
            "requestsAuthorizationLevel1": ${each.value.request_auth_level >= 1}
          }
        }'
    EOT
  }

  depends_on = [null_resource.create_safes]

  triggers = {
    safe_name   = each.value.safe_name
    member_name = each.value.member_name
    permissions = jsonencode(each.value)
  }
}

# L2+: Enforce dual-control approval for sensitive safes
resource "null_resource" "dual_control_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/MasterPolicy" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "policyName": "DualControl",
          "settings": {
            "requireDualControlPasswordAccessApproval": true,
            "enforceCheckInCheckOut": true,
            "exclusiveAccess": true
          }
        }'
    EOT
  }

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
