# =============================================================================
# HTH Fivetran Control 2.3: Configure SCIM Provisioning
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/fivetran/#23-configure-scim-provisioning
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable SCIM provisioning for automated user and group lifecycle (L2+)
# SCIM endpoint: https://api.fivetran.com/v1/scim
# Configure your IdP to push users/groups to this endpoint
resource "null_resource" "configure_scim" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
  }

  # Generate a SCIM API token and output the SCIM base URL
  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "SCIM Provisioning Setup (L2+)"
      echo "============================================="
      echo ""
      echo "Fivetran SCIM Base URL:"
      echo "  https://api.fivetran.com/v1/scim"
      echo ""
      echo "To generate a SCIM token via API:"
      echo ""

      RESPONSE=$(curl -s -X POST \
        "https://api.fivetran.com/v1/account/scim-token" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        -H "Content-Type: application/json")

      TOKEN=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
token = data.get('data', {}).get('token', '')
if token:
    print(f'SCIM Token generated successfully.')
    print(f'Token (first 8 chars): {token[:8]}...')
    print(f'Store this token securely -- it cannot be retrieved again.')
else:
    print('WARN: Could not generate SCIM token. Check API permissions.')
    print(f'Response: {json.dumps(data)}')
" 2>/dev/null || echo "Note: Python3 required for token parsing")

      echo ""
      echo "IdP Configuration Steps:"
      echo "  1. Add SCIM integration in your IdP"
      echo "  2. Set SCIM endpoint: https://api.fivetran.com/v1/scim"
      echo "  3. Enter the generated SCIM API token"
      echo "  4. Map IdP groups to Fivetran teams"
      echo "  5. Test user synchronization"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
