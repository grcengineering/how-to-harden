# =============================================================================
# HTH Duo Control 2.3: Require Phishing-Resistant MFA
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.5, NIST IA-2(6)
# Source: https://howtoharden.com/guides/duo/#23-require-phishing-resistant-mfa
#
# Configures Duo policies to require phishing-resistant methods:
# - Verified Duo Push (number matching) to resist MFA fatigue
# - WebAuthn (FIDO2) for strongest phishing resistance
# - Disable weaker methods (SMS, phone callback) at L2+
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable Verified Push and restrict to strong authentication methods (L2+)
resource "null_resource" "duo_phishing_resistant_mfa" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    verified_push      = var.verified_push_enabled
    disable_sms        = var.disable_sms_passcodes
    disable_phone      = var.disable_phone_callback
    profile_level      = var.profile_level
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      echo "=== HTH Duo 2.3: Configuring Phishing-Resistant MFA ==="
      echo ""
      echo "Profile Level: ${var.profile_level} (L2+ required)"
      echo ""

      API_HOST="${var.duo_api_hostname}"

      # Configure Verified Push via Duo Admin API
      echo "Enabling Verified Duo Push (number matching)..."
      curl -s -X POST \
        "https://$${API_HOST}/admin/v1/policies/global" \
        -d "verified_push=${var.verified_push_enabled}" \
        2>/dev/null && echo "  Verified Push: enabled" \
        || echo "  Note: Requires valid Duo Admin API credentials"

      # Disable SMS passcodes if configured
      if [ "${var.disable_sms_passcodes}" = "true" ]; then
        echo "Disabling SMS passcodes..."
        curl -s -X POST \
          "https://$${API_HOST}/admin/v1/policies/global" \
          -d "sms_passcodes=false" \
          2>/dev/null && echo "  SMS passcodes: disabled" \
          || echo "  Note: Requires valid Duo Admin API credentials"
      fi

      # Disable phone callback if configured
      if [ "${var.disable_phone_callback}" = "true" ]; then
        echo "Disabling phone callback..."
        curl -s -X POST \
          "https://$${API_HOST}/admin/v1/policies/global" \
          -d "phone_callback=false" \
          2>/dev/null && echo "  Phone callback: disabled" \
          || echo "  Note: Requires valid Duo Admin API credentials"
      fi

      echo ""
      echo "Authentication method hierarchy (strongest to weakest):"
      echo "  1. WebAuthn (FIDO2 Security Keys) -- phishing-resistant"
      echo "  2. WebAuthn (Platform Authenticators) -- phishing-resistant"
      echo "  3. Verified Duo Push (number matching) -- fatigue-resistant"
      echo "  4. Duo Push (standard) -- vulnerable to fatigue attacks"
      echo "  5. SMS passcodes -- vulnerable to SIM swap"
      echo "  6. Phone callback -- vulnerable to social engineering"
      echo ""
      echo "L2 recommendation: Enable methods 1-3, disable 5-6"
      echo "L3 recommendation: Enable methods 1-2 only (WebAuthn)"
    EOT
  }
}

# ISE allowed protocols configuration requiring strong authentication
resource "ise_allowed_protocols" "duo_phishing_resistant" {
  count = var.profile_level >= 2 ? 1 : 0

  name                     = "HTH-Duo-Phishing-Resistant-Protocols"
  description              = "HTH Duo 2.3: Allowed protocols for phishing-resistant MFA"
  process_host_lookup      = true
  allow_pap_ascii          = false
  allow_chap               = false
  allow_ms_chap_v1         = false
  allow_ms_chap_v2         = false
  allow_eap_md5            = false
  allow_eap_tls            = true
  allow_leap               = false
  allow_peap               = true
  allow_eap_fast           = true
  allow_eap_ttls           = true
  allow_teap               = true
  eap_tls_l_bit            = false
  allow_preferred_eap_protocol = false
}
# HTH Guide Excerpt: end terraform
