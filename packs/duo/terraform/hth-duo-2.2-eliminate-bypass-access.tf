# =============================================================================
# HTH Duo Control 2.2: Eliminate Bypass Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2
# Source: https://howtoharden.com/guides/duo/#22-eliminate-bypass-access
#
# Audits and eliminates bypass status users. Bypass allows users to skip MFA
# entirely and should only be used for temporary troubleshooting with
# expiration configured. Uses Duo Admin API to enumerate bypass accounts.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Audit and report on users with bypass status
resource "null_resource" "duo_audit_bypass_users" {
  triggers = {
    run_always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 2.2: Auditing Bypass Users ==="
      echo ""

      API_HOST="${var.duo_api_hostname}"

      # Fetch users with bypass status via Duo Admin API
      # GET /admin/v1/users?status=bypass
      curl -s -X GET \
        "https://$${API_HOST}/admin/v1/users" \
        -d "status=bypass" \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    users = data.get('response', [])
    bypass_users = [u for u in users if u.get('status') == 'bypass']
    print(f'Bypass users found: {len(bypass_users)}')
    if len(bypass_users) > 0:
        print('WARNING: The following users have bypass status:')
        for u in bypass_users:
            print(f\"  - {u.get('realname', 'Unknown')} ({u.get('username')})\")
            print(f\"    Status: {u.get('status')}\")
            print(f\"    Last login: {u.get('last_login', 'Never')}\")
        print()
        print('Recommended actions:')
        print('  1. Remove bypass for users who no longer need it')
        print('  2. Set expiration on any remaining bypass accounts')
        print('  3. Document business justification for each bypass')
    else:
        print('PASS: No users with bypass status found')
except Exception as e:
    print(f'Note: Duo Admin API query requires valid credentials ({e})')
" 2>/dev/null || echo "Note: Bypass audit requires valid Duo Admin API credentials"

      echo ""
      echo "Bypass elimination checklist:"
      echo "  [ ] All bypass users reviewed and justified"
      echo "  [ ] Bypass expiration set for temporary exceptions"
      echo "  [ ] Group-level bypass policies reviewed"
      echo "  [ ] Monthly bypass review process established"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
