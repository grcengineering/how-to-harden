# =============================================================================
# HTH PagerDuty Control 1.3: Configure Account Owner Fallback
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/pagerduty/#13-configure-account-owner-fallback
# =============================================================================

# HTH Guide Excerpt: begin terraform
# The Account Owner always retains email/password login even when SSO is
# enabled. This cannot be disabled. This control ensures the Account Owner
# credentials are protected and the recovery procedure is documented.

resource "null_resource" "account_owner_fallback" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[HTH] Account Owner Fallback Access Check:"
      echo "[HTH]"

      # Identify the account owner
      OWNER=$(curl -s \
        "https://api.pagerduty.com/users?include[]=roles" \
        -H "Authorization: Token token=${var.pagerduty_api_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        | jq -r '[.users[] | select(.role == "owner")] | .[0] | "\(.name) <\(.email)>"')

      echo "[HTH]   Account Owner: $OWNER"
      echo "[HTH]"
      echo "[HTH]   Security Requirements:"
      echo "[HTH]     - Use strong password (20+ characters)"
      echo "[HTH]     - Store credentials in enterprise password vault"
      echo "[HTH]     - Account Owner can log in during SSO outage"
      echo "[HTH]     - Account Owner can temporarily enable password login for all users"
      echo "[HTH]"
      echo "[HTH]   Document your recovery procedure and store it securely."
    EOT
  }
}
# HTH Guide Excerpt: end terraform
