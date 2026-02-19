#!/usr/bin/env bash
# HTH HashiCorp Vault Control 5.1: Secure Jenkins Integration
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/hashicorp-vault/#51-secure-jenkins-integration

# HTH Guide Excerpt: begin cli-jenkins-integration
# Step 1: Create Jenkins-Specific Policy
vault policy write jenkins-secrets - <<EOF
# Read secrets for Jenkins builds
path "secret/data/jenkins/*" {
  capabilities = ["read"]
}

# Generate AWS credentials for deployments
path "aws/creds/jenkins-deploy" {
  capabilities = ["read"]
}

# No access to production secrets
path "secret/data/production/*" {
  capabilities = ["deny"]
}
EOF

# Step 2: Configure AppRole with Restrictions
vault write auth/approle/role/jenkins \
    token_policies="jenkins-secrets" \
    token_ttl=15m \
    token_max_ttl=30m \
    secret_id_ttl=1h \
    secret_id_num_uses=1 \
    token_bound_cidrs="10.0.0.0/8"
# HTH Guide Excerpt: end cli-jenkins-integration
