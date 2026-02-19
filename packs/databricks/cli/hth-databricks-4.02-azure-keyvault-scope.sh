#!/usr/bin/env bash
# HTH Databricks Control 4.2: Azure Key Vault Secret Scope
# Profile: L2 | NIST: SC-28
# https://howtoharden.com/guides/databricks/#42-external-secret-store-integration

# HTH Guide Excerpt: begin cli-azure-keyvault-scope
# Create Key Vault-backed secret scope
databricks secrets create-scope \
  --scope azure-kv-scope \
  --scope-backend-type AZURE_KEYVAULT \
  --resource-id /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/my-vault \
  --dns-name https://my-vault.vault.azure.net/
# HTH Guide Excerpt: end cli-azure-keyvault-scope
