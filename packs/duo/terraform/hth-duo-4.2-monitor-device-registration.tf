# =============================================================================
# HTH Duo Control 4.2: Monitor Device Registration
# Profile Level: L1 (Baseline)
# Frameworks: CIS 1.4, NIST CM-8
# Source: https://howtoharden.com/guides/duo/#42-monitor-device-registration
#
# Monitors device registrations to detect suspicious activity. New device
# registration after credential theft is a critical indicator of compromise.
# Uses Duo Admin API to enumerate registered devices and ISE endpoint
# custom attributes for tracking.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ISE endpoint custom attribute for Duo device registration tracking
resource "ise_endpoint_custom_attribute" "duo_registration_date" {
  name        = "HTH-Duo-Registration-Date"
  description = "HTH Duo 4.2: Date device was registered with Duo"
  type        = "String"
}

resource "ise_endpoint_custom_attribute" "duo_registration_user" {
  name        = "HTH-Duo-Registration-User"
  description = "HTH Duo 4.2: User who registered the device in Duo"
  type        = "String"
}

# Audit device registrations via Duo Admin API
resource "null_resource" "duo_audit_device_registrations" {
  triggers = {
    run_always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 4.2: Auditing Device Registrations ==="
      echo ""

      API_HOST="${var.duo_api_hostname}"

      # Fetch recent device registrations via Duo Admin API
      # GET /admin/v1/info/authentication_log
      curl -s -X GET \
        "https://$${API_HOST}/admin/v2/logs/authentication" \
        -d "mintime=$(date -d '-7 days' +%s 2>/dev/null || date -v-7d +%s 2>/dev/null)000" \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    logs = data.get('response', {}).get('authlogs', [])
    enrollments = [l for l in logs if 'enrollment' in l.get('reason', '').lower()]
    print(f'Authentication events (last 7 days): {len(logs)}')
    print(f'Enrollment/registration events: {len(enrollments)}')
    if enrollments:
        print()
        print('Recent device registrations:')
        for e in enrollments[:10]:
            print(f\"  - User: {e.get('user', {}).get('name', 'Unknown')}\")
            print(f\"    Device: {e.get('access_device', {}).get('hostname', 'Unknown')}\")
            print(f\"    Result: {e.get('result', 'Unknown')}\")
    else:
        print('No new device registrations in last 7 days')
except Exception as e:
    print(f'Note: Device audit requires valid Duo Admin API credentials ({e})')
" 2>/dev/null || echo "Note: Device registration audit requires valid Duo Admin API credentials"

      echo ""
      echo "Device monitoring checklist:"
      echo "  [ ] Alerts enabled for new device registrations"
      echo "  [ ] Authentication logs reviewed for registration events"
      echo "  [ ] SIEM integration configured for correlation"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "  [ ] L2: Trust Monitor enabled for anomaly detection"
      fi
    EOT
  }
}
# HTH Guide Excerpt: end terraform
