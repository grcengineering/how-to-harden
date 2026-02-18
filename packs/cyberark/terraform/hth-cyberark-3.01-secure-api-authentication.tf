# =============================================================================
# HTH CyberArk Control 3.1: Secure API Authentication
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SC-8
# Source: https://howtoharden.com/guides/cyberark/#31-secure-api-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable certificate-based API authentication
resource "null_resource" "api_cert_auth" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/ApiSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "certificateAuthentication": true,
            "clientCertificateRequired": true,
            "caValidation": true
          }
        }'
    EOT
  }

  triggers = {
    cert_auth = "enabled"
  }
}

# Configure API rate limiting
resource "null_resource" "api_rate_limiting" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/WebServices" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "maxConcurrentRequests": ${var.api_rate_limit_max_concurrent},
            "requestTimeoutSeconds": ${var.api_rate_limit_timeout},
            "enableRateLimiting": true
          }
        }'
    EOT
  }

  triggers = {
    max_concurrent = var.api_rate_limit_max_concurrent
    timeout        = var.api_rate_limit_timeout
  }
}

# Restrict API access to allowed IP addresses
resource "null_resource" "api_ip_restrictions" {
  count = length(var.api_allowed_ips) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/ApiSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "allowedSourceIPs": ${jsonencode(var.api_allowed_ips)},
            "restrictByIP": true
          }
        }'
    EOT
  }

  triggers = {
    allowed_ips = jsonencode(var.api_allowed_ips)
  }
}

# L2+: Enforce short-lived API tokens with automatic expiration
resource "null_resource" "api_token_expiration" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/ApiSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "tokenMaxLifetimeMinutes": 60,
            "requireTokenRefresh": true,
            "singleUseTokens": false
          }
        }'
    EOT
  }

  depends_on = [null_resource.api_cert_auth]

  triggers = {
    profile_level = var.profile_level
  }
}

# L3: Enforce single-use API tokens for maximum security
resource "null_resource" "api_single_use_tokens" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/ApiSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "tokenMaxLifetimeMinutes": 30,
            "requireTokenRefresh": true,
            "singleUseTokens": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.api_token_expiration]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
