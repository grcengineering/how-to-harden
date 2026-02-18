# =============================================================================
# HTH CyberArk Control 4.2: Implement Just-In-Time Access
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-2(6)
# Source: https://howtoharden.com/guides/cyberark/#42-implement-just-in-time-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# L2+: Configure exclusive access and one-time password via Master Policy
resource "null_resource" "jit_exclusive_access" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/MasterPolicy" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "policyName": "JustInTimeAccess",
          "settings": {
            "exclusiveAccess": true,
            "oneTimePassword": true,
            "autoRotateAfterRetrieval": true,
            "requireDualControlPasswordAccessApproval": true
          }
        }'
    EOT
  }

  triggers = {
    profile_level = var.profile_level
  }
}

# L2+: Configure access request workflow
resource "null_resource" "jit_request_workflow" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/MasterPolicy" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "policyName": "AccessRequestWorkflow",
          "settings": {
            "requireBusinessJustification": true,
            "requireTicketNumber": true,
            "accessExpirationMinutes": 240,
            "autoApproveAfterMinutes": 0,
            "notifyApproversOnRequest": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.jit_exclusive_access]

  triggers = {
    profile_level = var.profile_level
  }
}

# L3: Enforce time-boxed access with automatic credential rotation
resource "null_resource" "jit_time_boxed_access" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/MasterPolicy" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "policyName": "TimeBoxedAccess",
          "settings": {
            "exclusiveAccess": true,
            "oneTimePassword": true,
            "autoRotateAfterRetrieval": true,
            "accessExpirationMinutes": 60,
            "enforceCheckInCheckOut": true,
            "requireMultipleApprovers": true,
            "minApprovers": 2
          }
        }'
    EOT
  }

  depends_on = [null_resource.jit_request_workflow]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
