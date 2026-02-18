# =============================================================================
# HTH CyberArk Control 4.1: Configure PSM Session Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-12, AU-14
# Source: https://howtoharden.com/guides/cyberark/#41-configure-psm-session-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable session recording for all PSM platforms
resource "null_resource" "psm_session_recording" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "sessionRecording": ${var.session_recording_enabled},
            "recordingFormat": "Universal",
            "recordingEncryption": true
          }
        }'
    EOT
  }

  triggers = {
    recording_enabled = var.session_recording_enabled
  }
}

# Configure session timeouts
resource "null_resource" "psm_session_timeouts" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "maxSessionDuration": ${var.session_max_duration_minutes},
            "idleSessionTimeout": ${var.session_idle_timeout_minutes},
            "warningBeforeTimeout": 5
          }
        }'
    EOT
  }

  triggers = {
    max_duration = var.session_max_duration_minutes
    idle_timeout = var.session_idle_timeout_minutes
  }
}

# Enable real-time session monitoring for security team
resource "null_resource" "psm_live_monitoring" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PSMSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "enableLiveMonitoring": true,
            "allowSessionSuspension": true,
            "allowSessionTermination": true
          }
        }'
    EOT
  }

  triggers = {
    monitoring = "enabled"
  }
}

# L2+: Enforce stricter session controls
resource "null_resource" "psm_strict_session_controls" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "maxSessionDuration": 240,
            "idleSessionTimeout": 15,
            "warningBeforeTimeout": 5,
            "requireReauthOnResume": true,
            "blockClipboardTransfer": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.psm_session_timeouts]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
