# =============================================================================
# HTH Ping Identity Control 2.3: Certificate Lifecycle Management
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-12
# Source: https://howtoharden.com/guides/ping-identity/#23-certificate-lifecycle-management
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Notification policy for certificate expiry warnings
resource "pingone_notification_policy" "cert_expiry_warning" {
  environment_id = var.pingone_environment_id
  name           = "HTH Certificate Expiry Warning"
}

# Alert condition: certificate approaching expiry (configurable threshold)
resource "pingone_alert_channel" "cert_expiry" {
  environment_id = var.pingone_environment_id
  alert_name     = "HTH Certificate Expiry Alert"

  addresses = var.siem_webhook_url != "" ? [var.siem_webhook_url] : []

  channel_type   = "EMAIL"
  include_severity = ["WARNING", "ERROR"]
}

# Dual certificate rotation support -- secondary signing key
# Deploy the new key before the old one expires, coordinate with SPs
resource "pingone_key" "saml_signing_rotation" {
  environment_id = var.pingone_environment_id
  name           = "HTH SAML Signing Key (Rotation)"
  algorithm      = "RSA"
  key_length     = 2048
  signature_algorithm = "SHA256withRSA"
  subject_dn     = "CN=PingOne SAML Signing Rotation, O=HTH Hardened"
  usage_type     = "SIGNING"
  validity_period = 365

  # This key exists for planned rotation -- activate when primary nears expiry
  default = false
}

# L2+: Shorter certificate validity for tighter rotation cycles
resource "pingone_key" "short_lived_signing" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH Short-Lived Signing Key"
  algorithm      = "RSA"
  key_length     = 2048
  signature_algorithm = "SHA256withRSA"
  subject_dn     = "CN=PingOne Short-Lived Signing, O=HTH Hardened"
  usage_type     = "SIGNING"
  validity_period = 180
}
# HTH Guide Excerpt: end terraform
