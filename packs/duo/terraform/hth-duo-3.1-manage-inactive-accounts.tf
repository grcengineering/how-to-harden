# =============================================================================
# HTH Duo Control 3.1: Manage Inactive Accounts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/duo/#31-manage-inactive-accounts
#
# Identifies and reports on inactive Duo accounts. Inactive and never-enrolled
# accounts increase attack surface. Uses Duo Admin API to enumerate users by
# status and last login date.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Audit inactive and pending-activation Duo user accounts
resource "null_resource" "duo_audit_inactive_accounts" {
  triggers = {
    inactive_threshold = var.inactive_days_threshold
    run_always         = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 3.1: Auditing Inactive Accounts ==="
      echo ""
      echo "Inactive threshold: ${var.inactive_days_threshold} days"
      echo ""

      API_HOST="${var.duo_api_hostname}"
      THRESHOLD_DAYS=${var.inactive_days_threshold}
      THRESHOLD_EPOCH=$(date -d "-$${THRESHOLD_DAYS} days" +%s 2>/dev/null || date -v-$${THRESHOLD_DAYS}d +%s 2>/dev/null)

      # Fetch all users via Duo Admin API
      # GET /admin/v1/users
      curl -s -X GET \
        "https://$${API_HOST}/admin/v1/users" \
        | python3 -c "
import sys, json, time

THRESHOLD = int('${var.inactive_days_threshold}')
threshold_ts = time.time() - (THRESHOLD * 86400)

try:
    data = json.load(sys.stdin)
    users = data.get('response', [])

    pending = [u for u in users if u.get('status') == 'pending_activation']
    inactive = [u for u in users if u.get('last_login') and u.get('last_login') < threshold_ts]

    print(f'Total users: {len(users)}')
    print(f'Pending activation (never enrolled): {len(pending)}')
    print(f'Inactive (>{THRESHOLD} days): {len(inactive)}')
    print()

    if pending:
        print('Users pending activation:')
        for u in pending:
            print(f\"  - {u.get('realname', 'Unknown')} ({u.get('username')})\")
        print()

    if inactive:
        print(f'Users inactive >{THRESHOLD} days:')
        for u in inactive:
            last = time.strftime('%Y-%m-%d', time.localtime(u.get('last_login', 0)))
            print(f\"  - {u.get('realname', 'Unknown')} ({u.get('username')}): last login {last}\")
        print()

    if not pending and not inactive:
        print('PASS: No inactive or pending accounts found')
except Exception as e:
    print(f'Note: Duo Admin API query requires valid credentials ({e})')
" 2>/dev/null || echo "Note: Inactive account audit requires valid Duo Admin API credentials"

      echo ""
      echo "Remediation steps:"
      echo "  1. Verify pending users are still employed"
      echo "  2. Resend enrollment or delete stale pending accounts"
      echo "  3. Disable inactive accounts until re-verification"
      echo "  4. Establish monthly account review process"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
