# =============================================================================
# HTH CyberArk Control 5.2: Monitor Rotation Failures
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5(1)
# Source: https://howtoharden.com/guides/cyberark/#52-monitor-rotation-failures
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Check for CPM password rotation failures
resource "null_resource" "rotation_failure_check" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X GET \
        "${var.pvwa_url}/PasswordVault/API/Accounts?filter=cpmStatus eq failure" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
accounts = data.get('value', [])
failed = [a for a in accounts if a.get('secretManagement', {}).get('status') == 'failure']
if failed:
    print(f'WARNING: {len(failed)} account(s) with rotation failures:')
    for acct in failed:
        name = acct.get('name', 'unknown')
        safe = acct.get('safeName', 'unknown')
        reason = acct.get('secretManagement', {}).get('lastModifiedReason', 'unknown')
        print(f'  - {name} in {safe}: {reason}')
    sys.exit(1)
else:
    print('OK: No rotation failures detected')
"
    EOT
  }

  triggers = {
    check_interval = timestamp()
  }
}

# Configure alerting for rotation failures
resource "null_resource" "rotation_failure_alerting" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/Notifications" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "notifyOnCPMFailure": true,
            "notifyOnVerificationFailure": true,
            "notifyOnReconcileFailure": true,
            "failureNotificationRecipients": "security-team"
          }
        }'
    EOT
  }

  triggers = {
    notification_config = "enabled"
  }
}

# L2+: Configure automatic reconciliation on rotation failure
resource "null_resource" "auto_reconcile_on_failure" {
  count = var.profile_level >= 2 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -sk -X PUT \
        "${var.pvwa_url}/PasswordVault/API/Configuration/PlatformConfiguration" \
        -H "Authorization: ${var.pvwa_auth_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "settings": {
            "autoReconcileOnFailure": true,
            "maxReconcileAttempts": 3,
            "reconcileRetryIntervalMinutes": 30
          }
        }'
    EOT
  }

  triggers = {
    profile_level = var.profile_level
  }
}
# HTH Guide Excerpt: end terraform
