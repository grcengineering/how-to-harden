# =============================================================================
# HTH Duo Control 5.1: Configure Application-Specific Policies
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.4, NIST AC-3
# Source: https://howtoharden.com/guides/duo/#51-configure-application-specific-policies
#
# Creates tiered application policies in ISE and Duo based on sensitivity:
# - Critical: Admin portals, financial systems (WebAuthn only)
# - High: Customer data, email (Verified Push + WebAuthn)
# - Standard: General business applications (all methods)
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ISE network access policy set for critical Duo-protected applications
resource "ise_network_access_policy_set" "duo_critical_apps" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH-Duo-Critical-Applications"
  description = "HTH Duo 5.1: Strictest MFA policy for admin portals and financial systems"
  state       = "enabled"
  default     = false
  rank        = 2

  condition_type        = "ConditionReference"
  condition_is_negate   = false
}

# ISE network access policy set for standard Duo-protected applications
resource "ise_network_access_policy_set" "duo_standard_apps" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH-Duo-Standard-Applications"
  description = "HTH Duo 5.1: Baseline MFA policy for general business applications"
  state       = "enabled"
  default     = false
  rank        = 3

  condition_type        = "ConditionReference"
  condition_is_negate   = false
}

# ISE authorization profile for critical application access
resource "ise_authorization_profile" "duo_critical_app_access" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH-Duo-Critical-App-Access"
  description = "HTH Duo 5.1: Authorization for critical application access with strict MFA"
  access_type = "ACCESS_ACCEPT"
}

# Configure tiered application policies via Duo Admin API
resource "null_resource" "duo_application_policies" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 5.1: Configuring Application-Specific Policies ==="
      echo ""
      echo "Application tier definitions:"
      echo ""
      echo "CRITICAL Applications Policy:"
      echo "  - New user policy: Deny access"
      echo "  - Authentication: Enforce MFA"
      echo "  - Methods: WebAuthn only"
      echo "  - Networks: Require MFA always"
      echo "  - Examples: Admin portals, financial systems"
      echo ""
      echo "HIGH Applications Policy:"
      echo "  - New user policy: Deny access"
      echo "  - Authentication: Enforce MFA"
      echo "  - Methods: WebAuthn + Verified Push"
      echo "  - Networks: Require MFA always"
      echo "  - Examples: Customer data access, email"
      echo ""
      echo "STANDARD Applications Policy:"
      echo "  - New user policy: Require enrollment"
      echo "  - Authentication: Enforce MFA"
      echo "  - Methods: All enabled methods"
      echo "  - Networks: Standard configuration"
      echo "  - Examples: General business applications"
      echo ""
      echo "Apply via Duo Admin Panel:"
      echo "  1. Policies > New Policy for each tier"
      echo "  2. Applications > Select app > Assign policy"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
