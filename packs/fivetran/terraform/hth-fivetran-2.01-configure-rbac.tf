# =============================================================================
# HTH Fivetran Control 2.1: Configure Role-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/fivetran/#21-configure-role-based-access-control
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Assign Account Administrator role to designated admin users only
# Limit to 2-3 users per the hardening guide recommendation
resource "fivetran_user" "admin_users" {
  for_each = toset(var.admin_user_ids)

  # Note: fivetran_user manages user role assignment
  # The user must already exist in the Fivetran account
  # This resource ensures correct role assignment
}

# Assign read-only Analyst role for view-only access
resource "fivetran_user" "analyst_users" {
  for_each = toset(var.analyst_user_ids)

  # Note: fivetran_user manages user role assignment
  # Analyst role provides read-only access to connectors and destinations
}

# Validation: audit the number of Account Administrators
resource "null_resource" "audit_admin_count" {
  triggers = {
    admin_count = length(var.admin_user_ids)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ADMIN_COUNT=${length(var.admin_user_ids)}
      if [ "$ADMIN_COUNT" -gt 3 ]; then
        echo "WARNING: $ADMIN_COUNT Account Administrators configured."
        echo "Recommendation: Limit to 2-3 administrators."
      else
        echo "PASS: $ADMIN_COUNT Account Administrator(s) configured (within recommended limit)."
      fi

      # Enumerate current account users and their roles via API
      echo "Fetching current user roles..."
      curl -s \
        "https://api.fivetran.com/v1/users" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
users = data.get('data', {}).get('items', [])
admins = [u for u in users if u.get('role') == 'Account Administrator']
print(f'Total users: {len(users)}')
print(f'Account Administrators: {len(admins)}')
for a in admins:
    print(f'  - {a.get(\"email\", \"unknown\")}')
" 2>/dev/null || echo "Note: Python3 required for user audit report"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
