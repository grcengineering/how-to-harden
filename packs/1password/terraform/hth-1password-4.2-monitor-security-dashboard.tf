# =============================================================================
# HTH 1Password Control 4.2: Monitor Security Dashboard
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#42-monitor-security-dashboard
# =============================================================================
#
# The 1Password security dashboard (Watchtower) monitors for compromised,
# weak, and reused passwords, and tracks 2FA adoption. Dashboard monitoring
# is manual but this control documents the review cadence and stores
# baseline metrics for audit tracking.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Document security dashboard review requirements.
resource "null_resource" "verify_security_dashboard" {
  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================================="
      echo "HTH 1Password Control 4.2: Security Dashboard"
      echo "======================================================="
      echo ""
      echo "Profile Level: ${var.profile_level}"
      echo ""
      echo "Navigate to: Admin Console > Security"
      echo ""
      echo "Watchtower Monitoring Checklist:"
      echo "  [ ] Compromised passwords identified and remediated"
      echo "  [ ] Weak passwords flagged for rotation"
      echo "  [ ] Reused passwords identified across vaults"
      echo "  [ ] 2FA adoption tracked and improving"
      echo ""
      echo "Review cadence by profile level:"
      if [ "${var.profile_level}" -ge 3 ]; then
        echo "  L3: Weekly review required"
        echo "    - Zero tolerance for compromised passwords"
        echo "    - 100% 2FA adoption target"
        echo "    - Automated alerts for new Watchtower findings"
      elif [ "${var.profile_level}" -ge 2 ]; then
        echo "  L2: Bi-weekly review required"
        echo "    - Compromised passwords remediated within 24h"
        echo "    - 95% 2FA adoption target"
      else
        echo "  L1: Monthly review required"
        echo "    - Compromised passwords remediated within 72h"
        echo "    - Track 2FA adoption progress"
      fi
      echo ""
      echo "Action items for findings:"
      echo "  1. Notify users of compromised passwords"
      echo "  2. Enforce password updates for weak items"
      echo "  3. Track 2FA adoption progress toward target"
    EOT
  }
}

# Store security dashboard review baseline.
resource "onepassword_item" "security_dashboard_baseline" {
  vault    = onepassword_vault.infrastructure[0].uuid
  title    = "HTH Security Dashboard Review Baseline"
  category = "secure_note"

  section {
    label = "Review Configuration"

    field {
      label = "Profile Level"
      value = tostring(var.profile_level)
      type  = "STRING"
    }

    field {
      label = "Review Cadence"
      value = var.profile_level >= 3 ? "Weekly" : var.profile_level >= 2 ? "Bi-weekly" : "Monthly"
      type  = "STRING"
    }

    field {
      label = "Compromised Password SLA"
      value = var.profile_level >= 3 ? "Immediate" : var.profile_level >= 2 ? "24 hours" : "72 hours"
      type  = "STRING"
    }

    field {
      label = "2FA Adoption Target"
      value = var.profile_level >= 3 ? "100%" : var.profile_level >= 2 ? "95%" : "Track progress"
      type  = "STRING"
    }

    field {
      label = "Baseline Established"
      value = timestamp()
      type  = "STRING"
    }
  }

  tags = ["hth-hardening", "security-dashboard", "watchtower"]
}

# HTH Guide Excerpt: end terraform
