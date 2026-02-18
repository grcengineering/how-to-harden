# =============================================================================
# HTH Splunk Control 3.2: Configure Encryption
# Profile Level: L1 (Baseline), enhanced at L2
# Frameworks: CIS 3.11, NIST SC-8/SC-28
# Source: https://howtoharden.com/guides/splunk/#32-configure-encryption
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Ensure data encryption in transit and at rest.
# Splunk Cloud uses TLS by default; these settings harden the configuration.

# Enforce TLS on HTTP Event Collector
resource "splunk_global_http_event_collector" "hec_ssl" {
  disabled   = false
  enable_ssl = var.hec_enable_ssl
  port       = var.hec_port
}

# Enforce TLS settings in server.conf (L2+)
resource "splunk_configs_conf" "ssl_hardening" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "server/sslConfig"

  variables = {
    "sslVersions"                 = "tls1.2"
    "sslVersionsForClient"        = "tls1.2"
    "cipherSuite"                 = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
    "ecdhCurves"                  = "prime256v1, secp384r1, secp521r1"
    "allowSslRenegotiation"       = "false"
    "requireClientCert"           = "false"
    "sslVerifyServerCert"         = "true"
    "sendStrictTransportSecurity" = "true"
  }
}

# Enforce TLS on web.conf for UI access (L2+)
resource "splunk_configs_conf" "web_ssl_hardening" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "web/settings"

  variables = {
    "enableSplunkWebSSL"       = "true"
    "cipherSuite"              = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
    "ecdhCurves"               = "prime256v1, secp384r1, secp521r1"
    "sendStrictTransportSecurityHeader" = "true"
  }
}

# L3: Force TLS 1.3 only where supported
resource "splunk_configs_conf" "tls13_enforcement" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "server/sslConfig"

  variables = {
    "sslVersions"          = "tls1.3"
    "sslVersionsForClient" = "tls1.3"
  }
}
# HTH Guide Excerpt: end terraform
