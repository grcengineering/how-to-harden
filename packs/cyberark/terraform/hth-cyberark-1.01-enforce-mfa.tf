# =============================================================================
# HTH CyberArk Control 1.1: Enforce Multi-Factor Authentication for All Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/6.5, NIST IA-2(1)/IA-2(6), PCI DSS 8.3.1
# Source: https://howtoharden.com/guides/cyberark/#11-enforce-multi-factor-authentication-for-all-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure RADIUS MFA authentication method via PVWA API
resource "null_resource" "mfa_radius_config" {
  count = var.mfa_radius_server != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/AuthenticationMethods/radius" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "id": "radius",
          "displayName": "RADIUS MFA",
          "enabled": true,
          "settings": {
            "server": "${var.mfa_radius_server}",
            "port": ${var.mfa_radius_port},
            "timeout": ${var.mfa_radius_timeout}
          }
        }'
    EOT
  }

  triggers = {
    radius_server  = var.mfa_radius_server
    radius_port    = var.mfa_radius_port
    radius_timeout = var.mfa_radius_timeout
  }
}

# L2+: Disable "Remember Device" for MFA to enforce every-session verification
resource "null_resource" "mfa_disable_remember_device" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/AuthenticationMethods/radius" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "id": "radius",
          "displayName": "RADIUS MFA",
          "enabled": true,
          "settings": {
            "server": "${var.mfa_radius_server}",
            "port": ${var.mfa_radius_port},
            "timeout": ${var.mfa_radius_timeout},
            "rememberDevice": false
          }
        }'
    EOT
  }

  depends_on = [null_resource.mfa_radius_config]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
