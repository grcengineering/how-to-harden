#!/usr/bin/env bash
# =============================================================================
# HTH Snowflake Control 1.2: Generate RSA Key Pair for Service Accounts
# Profile: L1 | NIST: IA-5
# =============================================================================

# HTH Guide Excerpt: begin cli-generate-key-pair
# Generate private key (keep secure!)
openssl genrsa -out rsa_key.pem 2048

# Generate public key
openssl rsa -in rsa_key.pem -pubout -out rsa_key.pub

# Extract public key in Snowflake format
grep -v "PUBLIC KEY" rsa_key.pub | tr -d '\n'
# HTH Guide Excerpt: end cli-generate-key-pair
