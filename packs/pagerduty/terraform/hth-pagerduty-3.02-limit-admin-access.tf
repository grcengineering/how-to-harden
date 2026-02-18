# =============================================================================
# HTH PagerDuty Control 3.2: Limit Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/pagerduty/#32-limit-admin-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Validate that admin count does not exceed the configured maximum.
# PagerDuty best practice: limit admins to 2-3 users.

# Fetch all users to audit admin count
data "pagerduty_users" "all" {}

# Check: fail the plan if too many admin user IDs are provided
resource "null_resource" "admin_count_check" {
  count = length(var.admin_user_ids) > var.max_admin_count ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "[HTH] WARNING: ${length(var.admin_user_ids)} admin user IDs provided."
      echo "[HTH] Maximum recommended: ${var.max_admin_count}"
      echo "[HTH] Review and reduce admin assignments to meet least privilege."
      exit 1
    EOT
  }
}

# Audit current admin users via API
resource "null_resource" "audit_admins" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[HTH] Auditing PagerDuty admin users..."
      ADMINS=$(curl -s \
        "https://api.pagerduty.com/users?include[]=roles" \
        -H "Authorization: Token token=${var.pagerduty_api_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        | jq '[.users[] | select(.role == "admin" or .role == "owner")] | length')
      echo "[HTH] Current admin/owner count: $ADMINS"
      echo "[HTH] Maximum recommended: ${var.max_admin_count}"
      if [ "$ADMINS" -gt "${var.max_admin_count}" ]; then
        echo "[HTH] FINDING: Admin count exceeds recommended maximum."
        echo "[HTH] ACTION: Demote non-essential admins to Manager or Responder role."
      else
        echo "[HTH] PASS: Admin count within acceptable range."
      fi
    EOT
  }
}
# HTH Guide Excerpt: end terraform
