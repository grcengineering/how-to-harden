# =============================================================================
# HTH PagerDuty Control 2.2: Configure SCIM Provisioning
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/pagerduty/#22-configure-scim-provisioning
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Note: PagerDuty SCIM provisioning is configured via the PagerDuty UI
# (Account Settings > SCIM). The Terraform provider does not expose a
# native SCIM configuration resource.
#
# This file validates SCIM readiness and outputs configuration guidance
# when profile_level >= 2.

resource "null_resource" "configure_scim" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
    scim_token    = sha256(var.scim_token)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[HTH] SCIM Provisioning Configuration (L2):"
      echo "[HTH]   1. Navigate to Account Settings > SCIM"
      echo "[HTH]   2. Generate SCIM API token"
      echo "[HTH]   3. Copy SCIM base URL: https://app.pagerduty.com/scim/v2"
      echo "[HTH]   4. Configure IdP SCIM integration with:"
      echo "[HTH]      - Base URL: https://app.pagerduty.com/scim/v2"
      echo "[HTH]      - Bearer Token: (generated in step 2)"
      echo "[HTH]   5. Enable user deprovisioning in IdP"
      echo "[HTH]   6. Test: create user in IdP, verify appears in PagerDuty"
      echo "[HTH]   7. Test: remove user in IdP, verify deprovisioned in PagerDuty"
      if [ -n "${var.scim_token}" ]; then
        echo "[HTH] SCIM token provided -- validating connectivity..."
        STATUS=$(curl -s -o /dev/null -w "%%{http_code}" \
          "https://app.pagerduty.com/scim/v2/Users?count=1" \
          -H "Authorization: Bearer ${var.scim_token}" \
          -H "Content-Type: application/scim+json")
        if [ "$STATUS" = "200" ]; then
          echo "[HTH] SCIM endpoint reachable (HTTP 200)"
        else
          echo "[HTH] WARNING: SCIM endpoint returned HTTP $STATUS"
        fi
      else
        echo "[HTH] No SCIM token provided -- skipping connectivity check"
      fi
    EOT
  }
}
# HTH Guide Excerpt: end terraform
