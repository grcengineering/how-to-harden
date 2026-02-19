#!/usr/bin/env bash
# HTH HashiCorp Vault Control 2.3: Enable Transit Engine for Encryption-as-a-Service
# Profile: L2 | NIST: SC-28
# https://howtoharden.com/guides/hashicorp-vault/#23-enable-transit-engine-for-encryption-as-a-service

# HTH Guide Excerpt: begin cli-configure-transit
# Enable transit
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/payment-data \
    type=aes256-gcm96 \
    exportable=false \
    allow_plaintext_backup=false

# Encrypt data
vault write transit/encrypt/payment-data \
    plaintext=$(echo "4111111111111111" | base64)

# Decrypt data
vault write transit/decrypt/payment-data \
    ciphertext="vault:v1:..."

# Enable key rotation
vault write -f transit/keys/payment-data/rotate

# Configure minimum decryption version (after key rotation)
vault write transit/keys/payment-data/config \
    min_decryption_version=2
# HTH Guide Excerpt: end cli-configure-transit
