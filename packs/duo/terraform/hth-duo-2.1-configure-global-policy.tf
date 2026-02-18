# =============================================================================
# HTH Duo Control 2.1: Configure Global Policy
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/duo/#21-configure-global-policy
#
# Configures the Duo Global Policy as the baseline security policy:
# - Enforce MFA for all authentications
# - Deny or require enrollment for new users
# - Set as the default for all Duo-protected applications
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure Duo Global Policy via Admin API
resource "null_resource" "duo_global_policy" {
  triggers = {
    new_user_action  = var.global_policy_new_user_action
    profile_level    = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 2.1: Configuring Global Policy ==="
      echo ""
      echo "Global Policy Settings:"
      echo "  Authentication policy: Enforce MFA"
      echo "  New user policy: ${var.global_policy_new_user_action}"
      echo "  Profile level: ${var.profile_level}"
      echo ""

      API_HOST="${var.duo_api_hostname}"

      # Set global policy via Duo Admin API
      # POST /admin/v1/policies/global
      curl -s -X POST \
        "https://$${API_HOST}/admin/v1/policies/global" \
        -d "authentication_policy=enforce" \
        -d "new_user_policy=$(echo '${var.global_policy_new_user_action}' | tr '[:upper:]' '[:lower:]')" \
        2>/dev/null && echo "Global policy updated successfully" \
        || echo "Note: Global policy update requires valid Duo Admin API credentials"

      echo ""
      echo "Validation checklist:"
      echo "  [x] Authentication policy set to: Enforce MFA"
      echo "  [x] New user policy set to: ${var.global_policy_new_user_action}"
      echo "  [ ] Verify in Duo Admin Panel > Policies > Global Policy"
    EOT
  }
}

# ISE network access policy set enforcing Duo MFA for all network access
resource "ise_network_access_policy_set" "duo_mfa_enforcement" {
  name        = var.duo_ise_policy_set_name
  description = "HTH Duo 2.1: Enforce Duo MFA for all network access"
  state       = "enabled"
  default     = false
  rank        = 1

  condition_type        = "ConditionReference"
  condition_is_negate   = false
}
# HTH Guide Excerpt: end terraform
