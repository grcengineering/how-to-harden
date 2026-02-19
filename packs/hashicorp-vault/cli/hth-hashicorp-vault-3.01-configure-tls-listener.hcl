# HTH HashiCorp Vault Control 3.1: Configure TLS and API Security
# Profile: L1 | NIST: SC-8
# https://howtoharden.com/guides/hashicorp-vault/#31-configure-tls-and-api-security
#
# Deploy: Add to your vault.hcl server configuration file

# HTH Guide Excerpt: begin cli-tls-listener
# Listener configuration
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
  tls_min_version = "tls12"
  tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"

  # Client certificate verification (L2)
  tls_require_and_verify_client_cert = true
  tls_client_ca_file = "/vault/certs/client-ca.crt"
}

# API address
api_addr = "https://vault.company.com:8200"
cluster_addr = "https://vault-node:8201"

# Disable insecure TLS skip verify
disable_tls_cert_verification = false
# HTH Guide Excerpt: end cli-tls-listener
