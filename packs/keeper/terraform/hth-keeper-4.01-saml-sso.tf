# =============================================================================
# HTH Keeper Control 4.1: Configure SAML SSO
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/keeper/#41-configure-saml-sso
# =============================================================================
#
# Integrate Keeper with your SAML identity provider for centralized
# authentication via SSO Connect Cloud. Requires a Keeper SSO Connect
# Cloud license and a SAML 2.0 compatible identity provider.
#
# CRITICAL: Lock down the identity provider with MFA. A compromised IdP
# grants access to all Keeper vaults federated through SSO.
#
# Implementation: Keeper Commander CLI and Admin Console.
# SSO configuration is managed through the SSO Configuration panel.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SAML SSO integration (L2+)
resource "terraform_data" "saml_sso" {
  count = var.profile_level >= 2 && var.sso_entity_id != "" ? 1 : 0

  input = {
    entity_id     = var.sso_entity_id
    sso_url       = var.sso_url
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 4.1: SAML SSO Configuration (L2)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure SSO in Keeper Admin Console"
      echo ""
      echo "  Step 1: Configure SSO Connect Cloud"
      echo "  1. Navigate to: Admin Console > SSO Configuration"
      echo "  2. Click 'Add SSO Configuration'"
      echo "  3. Configure SAML settings:"
      echo "     - Entity ID: ${var.sso_entity_id}"
      echo "     - SSO URL: ${var.sso_url}"
      echo "     - Certificate: (uploaded separately)"
      echo ""
      echo "  Step 2: Configure Identity Provider"
      echo "  1. Create SAML application in IdP"
      echo "  2. Upload Keeper metadata"
      echo "  3. Configure attribute mappings:"
      echo "     - Email (required)"
      echo "     - First name, last name (optional)"
      echo "  4. Configure groups for role mapping"
      echo ""
      echo "  Step 3: SECURE THE SSO CONFIGURATION"
      echo "  [CRITICAL] Lock down IdP with MFA"
      echo "  [CRITICAL] Follow IdP security best practices"
      echo "  [CRITICAL] Ensure IdP admin accounts are secured"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-sso --add \\"
      echo "    --entity-id '${var.sso_entity_id}' \\"
      echo "    --sso-url '${var.sso_url}'"
      echo "============================================================"
    EOT
  }
}

# Store SSO configuration metadata for audit trail
resource "secretsmanager_login" "sso_config_record" {
  count = var.profile_level >= 2 && var.sso_entity_id != "" ? 1 : 0

  folder_uid = var.security_config_folder_uid
  title      = "HTH SAML SSO Configuration"

  login = "sso-saml-config"
  url   = var.sso_url

  notes = <<-EOT
    SAML SSO CONFIGURATION
    ========================
    Profile Level: L2 (Hardened)

    Entity ID: ${var.sso_entity_id}
    SSO URL: ${var.sso_url}
    Certificate: Uploaded via Admin Console

    Attribute Mappings:
    - Email (required)
    - First name (optional)
    - Last name (optional)

    Security Checklist:
    [ ] IdP locked down with MFA
    [ ] IdP admin accounts secured
    [ ] IdP follows security best practices
    [ ] Keeper admin accounts excluded from SSO (break-glass)

    Prerequisites:
    - Keeper SSO Connect Cloud license
    - SAML 2.0 compatible identity provider

    Last updated: Managed by Terraform
    Control: HTH Keeper 4.1
  EOT
}
# HTH Guide Excerpt: end terraform
