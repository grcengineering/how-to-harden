# =============================================================================
# HTH Sentry Control 1.2: Enforce Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/sentry/#12-enforce-two-factor-authentication
#
# NOTE: The jianyuan/sentry provider does not expose 2FA enforcement as a
# managed resource. 2FA enforcement is an organization-level setting managed
# via the Sentry UI or API.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# ---------------------------------------------------------------------------
# Two-factor authentication enforcement must be configured via Sentry UI
# or the Sentry API:
#
#   UI: Settings > Security > Require two-factor authentication
#
#   API (requires owner-level auth token):
#     PUT /api/0/organizations/{org_slug}/
#       { "require2FA": true }
#
# When SSO is configured (Control 1.1), enforce MFA at the IdP level
# using phishing-resistant methods (FIDO2/WebAuthn) for admin accounts.
#
# Verify 2FA enforcement:
#   GET /api/0/organizations/{org_slug}/
#     -> check "require2FA": true
# ---------------------------------------------------------------------------
# HTH Guide Excerpt: end terraform
