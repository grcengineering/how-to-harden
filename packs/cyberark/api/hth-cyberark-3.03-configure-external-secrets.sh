#!/usr/bin/env bash
# HTH CyberArk Control 3.03: Integrate with External Secrets Managers
# Profile: L2 | NIST: IA-5(7)
# https://howtoharden.com/guides/cyberark/#33-integrate-with-external-secrets-managers

set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR (HashiCorp Vault address)}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN (HashiCorp Vault token)}"

# HTH Guide Excerpt: begin api-external-secrets
# Configure Vault to retrieve from CyberArk
vault write auth/approle/role/cyberark \
    token_policies="cyberark-read" \
    token_ttl=1h \
    token_max_ttl=4h

# CyberArk Secrets Hub configuration
# Sync secrets to Vault while maintaining CyberArk as source of truth
# HTH Guide Excerpt: end api-external-secrets
