# =============================================================================
# HTH CyberArk Control 1.3: Configure Break-Glass Procedures
# Profile Level: L1 (Baseline)
# Frameworks: NIST CP-2
# Source: https://howtoharden.com/guides/cyberark/#13-configure-break-glass-procedures
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create break-glass emergency safe with enhanced controls
resource "null_resource" "break_glass_safe" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X POST \
        "${var.pvwa_url}/PasswordVault/API/Safes" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "safeName": "${var.break_glass_safe_name}",
          "description": "Emergency break-glass credentials - dual approval required",
          "olacEnabled": true,
          "managingCPM": "PasswordManager",
          "numberOfVersionsRetention": 20,
          "numberOfDaysRetention": 365
        }'
    EOT
  }

  triggers = {
    safe_name = var.break_glass_safe_name
  }
}

# Configure dual-approval workflow for break-glass safe
resource "null_resource" "break_glass_dual_approval" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Safes/${var.break_glass_safe_name}/Members" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "memberName": "BreakGlassApprovers",
          "memberType": "Group",
          "permissions": {
            "useAccounts": false,
            "retrieveAccounts": false,
            "listAccounts": true,
            "requestsAuthorizationLevel1": true,
            "requestsAuthorizationLevel2": true,
            "accessWithoutConfirmation": false
          }
        }'
    EOT
  }

  depends_on = [null_resource.break_glass_safe]

  triggers = {
    safe_name      = var.break_glass_safe_name
    approval_count = var.break_glass_approval_count
  }
}

# L3: Enforce enhanced logging and shorter expiration for break-glass
resource "null_resource" "break_glass_enhanced" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/MasterPolicy" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "policyName": "BreakGlassEnhanced",
          "settings": {
            "exclusiveAccess": true,
            "requireDualControlPasswordAccessApproval": true,
            "minApprovers": ${var.break_glass_approval_count},
            "accessExpirationHours": ${var.break_glass_expiration_hours},
            "enforceOneTimeAccess": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.break_glass_safe]

  triggers = {
    profile_level    = var.profile_level
    expiration_hours = var.break_glass_expiration_hours
  }
}
# HTH Guide Excerpt: end terraform
