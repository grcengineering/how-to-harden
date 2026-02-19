#!/usr/bin/env bash
# HTH HashiCorp Vault Control 1.1: Configure Auth Methods (ClickOps CLI)
# Profile: L1 | NIST: IA-2, IA-5, AC-2 | SOC 2: CC6.1
# https://howtoharden.com/guides/hashicorp-vault/#11-implement-least-privilege-auth-methods

set -euo pipefail

# HTH Guide Excerpt: begin cli-revoke-root-token
# After initial configuration, revoke root token
vault token revoke <root-token>

# Create admin policy for emergency use
vault policy write admin-emergency - <<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

# Create emergency token with TTL
vault token create -policy=admin-emergency -ttl=1h -use-limit=5
# HTH Guide Excerpt: end cli-revoke-root-token

# HTH Guide Excerpt: begin cli-configure-oidc
# Enable OIDC auth method
vault auth enable oidc

# Configure OIDC with your IdP
vault write auth/oidc/config \
    oidc_discovery_url="https://your-idp.okta.com" \
    oidc_client_id="$CLIENT_ID" \
    oidc_client_secret="$CLIENT_SECRET" \
    default_role="default"

# Create role mapping
vault write auth/oidc/role/default \
    bound_audiences="$CLIENT_ID" \
    allowed_redirect_uris="https://vault.company.com/ui/vault/auth/oidc/oidc/callback" \
    allowed_redirect_uris="http://localhost:8250/oidc/callback" \
    user_claim="email" \
    groups_claim="groups" \
    policies="default"
# HTH Guide Excerpt: end cli-configure-oidc

# HTH Guide Excerpt: begin cli-configure-approle
# Enable AppRole
vault auth enable approle

# Create role with limited TTL
vault write auth/approle/role/jenkins \
    token_policies="jenkins-secrets" \
    token_ttl=1h \
    token_max_ttl=4h \
    secret_id_ttl=24h \
    secret_id_num_uses=10

# Bind to specific CIDR (L2)
vault write auth/approle/role/jenkins \
    token_bound_cidrs="10.0.0.0/8" \
    secret_id_bound_cidrs="10.0.0.0/8"
# HTH Guide Excerpt: end cli-configure-approle

# HTH Guide Excerpt: begin cli-monitor-auth
# Monitor auth method usage
vault read sys/auth

# Check token counts by auth method
vault read sys/internal/counters/tokens
# HTH Guide Excerpt: end cli-monitor-auth
