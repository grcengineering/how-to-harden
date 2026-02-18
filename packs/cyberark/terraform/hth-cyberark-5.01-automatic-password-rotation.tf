# =============================================================================
# HTH CyberArk Control 5.1: Configure Automatic Password Rotation
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(1)
# Source: https://howtoharden.com/guides/cyberark/#51-configure-automatic-password-rotation
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure CPM password rotation policy
resource "null_resource" "cpm_rotation_policy" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "passwordChangeInterval": ${var.password_rotation_days},
            "verificationIntervalHours": ${var.password_verification_interval_hours},
            "reconcileIntervalDays": 7
          }
        }'
    EOT
  }

  triggers = {
    rotation_days         = var.password_rotation_days
    verification_interval = var.password_verification_interval_hours
  }
}

# Configure password complexity requirements
resource "null_resource" "password_complexity" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PasswordPolicy" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "minLength": ${var.password_min_length},
            "requireUppercase": true,
            "requireLowercase": true,
            "requireNumbers": true,
            "requireSpecial": true,
            "excludedCharacters": "\"<>;"
          }
        }'
    EOT
  }

  triggers = {
    min_length = var.password_min_length
  }
}

# L2+: Enforce aggressive rotation (7-day interval)
resource "null_resource" "aggressive_rotation" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "passwordChangeInterval": 7,
            "verificationIntervalHours": 12,
            "reconcileIntervalDays": 3,
            "autoRotateOnCheckIn": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.cpm_rotation_policy]

  triggers = {
    profile_level = var.profile_level
  }
}

# L3: Enforce one-time-use passwords with immediate rotation
resource "null_resource" "one_time_passwords" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "passwordChangeInterval": 1,
            "oneTimePassword": true,
            "autoRotateAfterRetrieval": true,
            "verificationIntervalHours": 6,
            "reconcileIntervalDays": 1
          }
        }'
    EOT
  }

  depends_on = [null_resource.aggressive_rotation]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
