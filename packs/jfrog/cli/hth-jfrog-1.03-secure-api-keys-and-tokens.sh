#!/usr/bin/env bash
# HTH JFrog Control 1.3: Secure API Keys and Tokens
# Profile: L1 | NIST: IA-5
# https://howtoharden.com/guides/jfrog/#13-secure-api-keys-and-tokens

# HTH Guide Excerpt: begin create-scoped-token
# Create scoped token via CLI
jf rt access-token-create \
  --groups readers \
  --scope applied-permissions/groups:readers \
  --expiry 7776000  # 90 days
# HTH Guide Excerpt: end create-scoped-token
