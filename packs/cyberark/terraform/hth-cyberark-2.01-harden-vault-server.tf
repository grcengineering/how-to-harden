# =============================================================================
# HTH CyberArk Control 2.1: Harden Vault Server Configuration
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-8, SC-28
# Source: https://howtoharden.com/guides/cyberark/#21-harden-vault-server-configuration
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Verify and enforce vault encryption settings via DBParm configuration
resource "null_resource" "vault_encryption_config" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X GET \
        "${var.pvwa_url}/PasswordVault/API/Configuration/Vault" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        | python3 -c "
import sys, json
config = json.load(sys.stdin)
encryption = config.get('encryptionMethod', 'UNKNOWN')
if encryption != 'AES256':
    print('WARNING: Encryption method is ' + encryption + ', expected AES256')
    sys.exit(1)
print('OK: Vault encryption is AES256')
"
    EOT
  }

  triggers = {
    check_interval = timestamp()
  }
}

# Enforce TLS 1.2+ for all vault communications
resource "null_resource" "vault_tls_config" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/WebServices" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "minTlsVersion": "1.2",
            "disableSSLv3": true,
            "disableTLS10": true,
            "disableTLS11": true
          }
        }'
    EOT
  }

  triggers = {
    tls_config = "tls12_enforced"
  }
}

# L3: Enforce TLS 1.3 only for maximum security
resource "null_resource" "vault_tls13_only" {
  count = var.profile_level >= 3 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/WebServices" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "minTlsVersion": "1.3",
            "disableSSLv3": true,
            "disableTLS10": true,
            "disableTLS11": true,
            "disableTLS12": true
          }
        }'
    EOT
  }

  depends_on = [null_resource.vault_tls_config]

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
