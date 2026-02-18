# =============================================================================
# HTH Keeper Control 5.3: BreachWatch Integration
# Profile Level: L1 (Baseline)
# Frameworks: CIS 16.4, NIST SI-4
# Source: https://howtoharden.com/guides/keeper/#53-breachwatch-integration
# =============================================================================
#
# BreachWatch detects compromised credentials by checking stored passwords
# against known breach databases. When credentials are detected in a breach,
# affected users must be notified and passwords rotated immediately.
#
# Implementation: Keeper Commander CLI and Admin Console.
# BreachWatch is enabled at the organization level and may require an
# add-on license depending on the Keeper plan.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable BreachWatch for compromised credential detection
resource "terraform_data" "breachwatch" {
  input = {
    breachwatch_enabled = var.breachwatch_enabled
    profile_level       = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 5.3: BreachWatch Integration (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Enable BreachWatch in Keeper Admin Console"
      echo ""
      echo "  Step 1: Enable BreachWatch"
      echo "  1. Navigate to: Admin Console > BreachWatch"
      echo "  2. Enable for organization"
      echo "  3. Configure alert settings"
      echo ""
      echo "  Step 2: Respond to Alerts"
      echo "  When compromised credentials are detected:"
      echo "  1. Notify affected users immediately"
      echo "  2. Require password change"
      echo "  3. Investigate exposure source"
      echo "  4. Document incident response"
      echo ""
      echo "  Plan Compatibility:"
      echo "  - Business: Add-on required"
      echo "  - Enterprise: Add-on required"
      echo "  - Enterprise Plus: Included"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander breachwatch --enable"
      echo "  keeper-commander breachwatch --scan"
      echo "============================================================"
    EOT
  }
}

# Store BreachWatch configuration for audit trail
resource "secretsmanager_login" "breachwatch_config_record" {
  count = var.breachwatch_enabled ? 1 : 0

  folder_uid = var.security_config_folder_uid
  title      = "HTH BreachWatch Configuration"

  login = "breachwatch-config"
  url   = "https://keepersecurity.com/console"

  notes = <<-EOT
    BREACHWATCH CONFIGURATION
    ===========================
    Profile Level: L1 (Baseline)

    BreachWatch Enabled: ${var.breachwatch_enabled}

    Incident Response Procedure:
    1. Alert triggers when credential found in breach database
    2. Security team notified via configured alerts
    3. Affected user notified to change password immediately
    4. Investigate scope of exposure
    5. Document in incident tracking system

    License Requirement:
    - Business: Add-on
    - Enterprise: Add-on
    - Enterprise Plus: Included

    Last updated: Managed by Terraform
    Control: HTH Keeper 5.3
  EOT
}
# HTH Guide Excerpt: end terraform
