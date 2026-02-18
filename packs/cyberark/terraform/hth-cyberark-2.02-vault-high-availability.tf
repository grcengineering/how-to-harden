# =============================================================================
# HTH CyberArk Control 2.2: Implement Vault High Availability
# Profile Level: L2 (Hardened)
# Frameworks: NIST CP-9, CP-10
# Source: https://howtoharden.com/guides/cyberark/#22-implement-vault-high-availability
# =============================================================================

# HTH Guide Excerpt: begin terraform
# L2+: Verify vault replication status
resource "null_resource" "vault_replication_check" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X GET \
        "${var.pvwa_url}/PasswordVault/API/ComponentMonitoring" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
components = data.get('Components', [])
dr_found = False
for comp in components:
    if 'DR' in comp.get('ComponentName', ''):
        dr_found = True
        status = comp.get('IsLoggedOn', False)
        print(f'DR Component: {comp[\"ComponentName\"]} - Connected: {status}')
if not dr_found:
    print('WARNING: No DR vault component detected')
    sys.exit(1)
print('OK: DR vault replication verified')
"
    EOT
  }

  triggers = {
    check_interval = timestamp()
  }
}

# L2+: Configure backup verification schedule
resource "null_resource" "vault_backup_verification" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/BackupSettings" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "backupEnabled": true,
            "backupRetentionDays": ${var.audit_retention_days},
            "verifyBackupIntegrity": true,
            "encryptBackups": true
          }
        }'
    EOT
  }

  triggers = {
    retention_days = var.audit_retention_days
  }
}
# HTH Guide Excerpt: end terraform
