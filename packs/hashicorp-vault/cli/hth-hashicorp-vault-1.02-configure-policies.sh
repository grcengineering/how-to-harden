#!/usr/bin/env bash
# HTH HashiCorp Vault Control 1.2: Configure Granular Policies (ClickOps CLI)
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/hashicorp-vault/#12-implement-granular-policies

set -euo pipefail

# HTH Guide Excerpt: begin cli-create-policies
# Base policy - all authenticated users
vault policy write base - <<EOF
path "secret/data/shared/*" {
  capabilities = ["read", "list"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF

# Team-specific policy
vault policy write team-platform - <<EOF
path "secret/data/platform/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "aws/creds/platform-deploy" {
  capabilities = ["read"]
}
EOF

# Application policy (most restrictive)
vault policy write app-frontend - <<EOF
path "secret/data/frontend/config" {
  capabilities = ["read"]
}
path "database/creds/frontend-readonly" {
  capabilities = ["read"]
}
EOF
# HTH Guide Excerpt: end cli-create-policies
