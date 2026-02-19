# HTH HashiCorp Vault Control 3.2: Implement Request Rate Limiting
# Profile: L2 | NIST: SC-5
# https://howtoharden.com/guides/hashicorp-vault/#32-implement-request-rate-limiting
#
# Deploy: Add to your vault.hcl server configuration file (Enterprise only)

# HTH Guide Excerpt: begin cli-rate-limiting
# In vault.hcl (Enterprise only)
default_lease_ttl = "1h"
max_lease_ttl = "24h"

# Rate limiting
rate_limit {
  rate = 100.0
  burst = 200

  # Per-path limits
  path {
    glob = "auth/*"
    rate = 50.0
    burst = 100
  }

  path {
    glob = "secret/*"
    rate = 200.0
    burst = 400
  }
}
# HTH Guide Excerpt: end cli-rate-limiting
