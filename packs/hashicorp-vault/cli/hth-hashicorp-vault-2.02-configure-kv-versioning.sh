#!/usr/bin/env bash
# HTH HashiCorp Vault Control 2.2: Implement Secrets Versioning and Rotation
# Profile: L1 | NIST: IA-5(1)
# https://howtoharden.com/guides/hashicorp-vault/#22-implement-secrets-versioning-and-rotation

# HTH Guide Excerpt: begin cli-configure-kv-versioning
# Enable KV v2
vault secrets enable -version=2 -path=secret kv

# Configure version retention
vault write secret/config \
    max_versions=10 \
    cas_required=true

# Write secret with CAS (check-and-set) for conflict prevention
vault kv put -cas=0 secret/myapp/config \
    api_key="secret123" \
    db_password="dbpass456"

# Read specific version
vault kv get -version=2 secret/myapp/config

# Delete version (soft delete)
vault kv delete -versions=1 secret/myapp/config

# Destroy version permanently (L3 only)
vault kv destroy -versions=1 secret/myapp/config
# HTH Guide Excerpt: end cli-configure-kv-versioning
