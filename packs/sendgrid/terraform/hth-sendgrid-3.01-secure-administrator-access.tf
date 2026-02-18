# =============================================================================
# HTH SendGrid Control 3.1: Secure Administrator Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/sendgrid/#31-secure-administrator-access
# =============================================================================
#
# NOTE: Administrator credential management (strong passwords, 2FA, vault storage)
# is an operational practice outside the scope of the Terraform provider.
# Terraform enforces the structural aspect: limiting admin accounts to a small
# number of teammates with is_admin=true.
#
# The teammate resources in Controls 1.3 and 3.2 enforce:
#   - Explicit admin designation (is_admin flag)
#   - Minimum-privilege scopes for non-admin users
#   - Centralized access inventory via Terraform state

# HTH Guide Excerpt: begin terraform
# Administrator access security is enforced through:
#   1. SSO teammates (hth-sendgrid-1.03) with explicit is_admin flags
#   2. Password teammates (hth-sendgrid-3.02) with role-based scopes
#   3. Terraform state provides a complete access inventory for auditing
#
# Operational requirements (outside Terraform):
#   - Admin accounts limited to 2-3 for redundancy
#   - 20+ character passwords stored in a vault
#   - 2FA enabled on all accounts (mandatory since Q4 2020)
#   - Quarterly access reviews
# HTH Guide Excerpt: end terraform
