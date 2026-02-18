# =============================================================================
# HTH SendGrid Control 1.1: Enable Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/sendgrid/#11-enable-two-factor-authentication
# =============================================================================
#
# NOTE: Two-factor authentication in SendGrid is a per-user setting that must
# be configured through the UI or Authy app. SendGrid has required 2FA for all
# accounts since Q4 2020. The Terraform provider does not expose a resource to
# enforce 2FA programmatically.
#
# Validation: Use the SendGrid API to verify 2FA status:
#   curl -s https://api.sendgrid.com/v3/user/settings/two_factor_authentication \
#     -H "Authorization: Bearer $SENDGRID_API_KEY"
#
# This file is a documentation placeholder. No Terraform resources are created.

# HTH Guide Excerpt: begin terraform
# Two-factor authentication is enforced at the account level by SendGrid.
# It cannot be managed via Terraform. Verify 2FA is active for all users
# through the SendGrid UI: Settings > Two-Factor Authentication.
# HTH Guide Excerpt: end terraform
