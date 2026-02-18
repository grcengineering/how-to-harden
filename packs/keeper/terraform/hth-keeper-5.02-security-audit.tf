# =============================================================================
# HTH Keeper Control 5.2: Monitor Security Audit
# Profile Level: L1 (Baseline)
# Frameworks: CIS 4.1, NIST CA-7
# Source: https://howtoharden.com/guides/keeper/#52-monitor-security-audit
# =============================================================================
#
# Use Security Audit to monitor organization password health. The Security
# Audit dashboard provides overall security score, password strength
# distribution, reused password detection, and 2FA adoption metrics.
#
# Implementation: Keeper Commander CLI for automated reporting.
# The Security Audit dashboard is available in the Admin Console.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure Security Audit monitoring and thresholds
resource "terraform_data" "security_audit" {
  input = {
    min_security_score = var.profile_level >= 3 ? 90 : var.profile_level >= 2 ? 80 : 70
    profile_level      = var.profile_level
    audit_metrics = [
      "overall_security_score",
      "password_strength_distribution",
      "reused_passwords",
      "2fa_adoption_rate",
      "weak_password_count",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 5.2: Security Audit Monitoring (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Review Security Audit in Keeper Admin Console"
      echo ""
      echo "  Step 1: Access Security Audit"
      echo "  1. Navigate to: Admin Console > Security Audit"
      echo "  2. Review dashboard metrics:"
      echo "     - Overall security score (target: ${var.profile_level >= 3 ? "90" : var.profile_level >= 2 ? "80" : "70"}+)"
      echo "     - Password strength distribution"
      echo "     - Reused passwords (target: 0)"
      echo "     - 2FA adoption (target: 100%)"
      echo ""
      echo "  Step 2: Identify and Remediate Issues"
      echo "  1. Review users with weak passwords"
      echo "  2. Identify reused credentials"
      echo "  3. Track 2FA compliance gaps"
      echo "  4. Notify non-compliant users"
      echo "  5. Set improvement targets"
      echo ""
      echo "  Recommended Audit Frequency:"
      echo "     - L1: Monthly review"
      echo "     - L2: Bi-weekly review"
      echo "     - L3: Weekly review with automated alerts"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander security-audit-report --format=json"
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
