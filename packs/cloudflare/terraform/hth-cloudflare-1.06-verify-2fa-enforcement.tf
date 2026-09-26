# =============================================================================
# HTH Cloudflare Control 1.6: Enforce Two-Factor Authentication for Account Members
# Profile Level: L1 (Crawl)
# Frameworks: NIST IA-2(1) | CIS 6.5
# Source: https://howtoharden.com/guides/cloudflare/#16-enforce-two-factor-authentication-for-account-members
#
# Verifies account-level 2FA enforcement (Terraform >= 1.5 `check` block).
# The setting itself is cloudflare_account.settings.enforce_twofactor; this
# pack deliberately does not write it. Enforcement blocks every member
# without 2FA, and cloudflare_account manages the whole account object
# (name, unit, abuse contact) -- adopting it needs an import of the existing
# account first. Turn enforcement on from the console as the guide describes.
# =============================================================================

# HTH Guide Excerpt: begin terraform
check "account_2fa_enforced" {
  data "cloudflare_account" "this" {
    account_id = var.cloudflare_account_id
  }

  assert {
    condition     = try(data.cloudflare_account.this.settings.enforce_twofactor, false) == true
    error_message = "Account-level 2FA enforcement is off: members can use the account without two-factor authentication."
  }
}
# HTH Guide Excerpt: end terraform
