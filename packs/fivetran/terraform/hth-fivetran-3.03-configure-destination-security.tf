# =============================================================================
# HTH Fivetran Control 3.3: Configure Destination Security
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-8
# Source: https://howtoharden.com/guides/fivetran/#33-configure-destination-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Secure data warehouse/destination configuration
# Use service accounts with minimum write permissions
resource "fivetran_destination" "primary" {
  count = var.destination_group_id != "" && var.destination_service != "" ? 1 : 0

  group_id           = var.destination_group_id
  service            = var.destination_service
  region             = "GCP_US_EAST4"
  time_zone_offset   = "0"
  run_setup_tests    = true
  trust_certs        = true
  trust_fingerprints = true

  config {
    # Destination-specific configuration is passed via variables
    # Ensure the service account has:
    #   - Minimum write permissions to target schemas/datasets
    #   - No admin/owner-level access to the data warehouse
    #   - TLS encryption enabled for the connection
  }
}

# Validate destination security configuration
resource "null_resource" "audit_destination_security" {
  count = var.destination_group_id != "" ? 1 : 0

  triggers = {
    destination_group_id = var.destination_group_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "Destination Security Audit"
      echo "============================================="
      echo ""

      # Fetch destination configuration
      curl -s \
        "https://api.fivetran.com/v1/destinations/${var.destination_group_id}" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
dest = data.get('data', {})
print(f'Destination: {dest.get(\"service\", \"unknown\")}')
print(f'Region: {dest.get(\"region\", \"unknown\")}')
print(f'Setup status: {dest.get(\"setup_status\", \"unknown\")}')
config = dest.get('config', {})
# Check for TLS/SSL indicators
has_ssl = any('ssl' in k.lower() or 'tls' in k.lower() for k in config.keys())
print(f'SSL/TLS configured: {\"Yes\" if has_ssl else \"Check manually\"}')
print('')
print('Destination Security Checklist:')
print('  [1] Service account with minimum write permissions')
print('  [2] No admin credentials used')
print('  [3] TLS encryption enabled')
print('  [4] Data encrypted at rest in destination')
print('  [5] Column-level security applied where needed')
" 2>/dev/null || echo "Note: Python3 required for destination audit report"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
