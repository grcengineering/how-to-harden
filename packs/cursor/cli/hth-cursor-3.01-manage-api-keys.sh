#!/usr/bin/env bash
# HTH Cursor Control 3.01: Use Environment Variables for API Keys (Never Hardcode)
# Profile: L1 | NIST: IA-5(1)
# https://howtoharden.com/guides/cursor/#31-use-environment-variables-for-api-keys-never-hardcode

set -euo pipefail

# --------------------------------------------------------------------------
# Anti-Pattern: Hardcoded API Keys (DO NOT DO THIS)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-bad-hardcoded-key
# BAD - Don't do this: hardcoded API key in settings.json
# {
#   "cursor.openai.apiKey": "sk-proj-abc123..."
# }
# HTH Guide Excerpt: end cli-bad-hardcoded-key

# --------------------------------------------------------------------------
# Option 1: Environment Variables (Recommended)
# Add to shell profile (~/.zshrc or ~/.bashrc)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-env-var-api-keys
# Store AI provider API keys in environment variables
# Add these to ~/.zshrc or ~/.bashrc
export OPENAI_API_KEY="sk-proj-..."
export ANTHROPIC_API_KEY="sk-ant-..."

# Verify keys are set
echo $OPENAI_API_KEY  # Should print key
# HTH Guide Excerpt: end cli-env-var-api-keys

# HTH Guide Excerpt: begin cli-reload-shell
# Reload shell to pick up new environment variables
source ~/.zshrc
# HTH Guide Excerpt: end cli-reload-shell

# --------------------------------------------------------------------------
# Option 2: Enterprise Secret Management
# Retrieve keys from organization secret manager at runtime
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-secret-manager-api-keys
# Use organization secret manager
# AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id cursor/openai-api-key --query SecretString --output text

# HashiCorp Vault
vault kv get -field=api_key secret/cursor/openai
# HTH Guide Excerpt: end cli-secret-manager-api-keys

# --------------------------------------------------------------------------
# Option 3: macOS Keychain
# Store and retrieve keys from the system keychain
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-keychain-api-keys
# Store in Keychain
security add-generic-password -a "$USER" -s "cursor-openai-key" -w "sk-proj-..."

# Retrieve in shell
security find-generic-password -a "$USER" -s "cursor-openai-key" -w
# HTH Guide Excerpt: end cli-keychain-api-keys

# --------------------------------------------------------------------------
# Verification: Check for Hardcoded Keys in Settings
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-verify-no-hardcoded-keys
# Search for hardcoded API keys in Cursor settings
grep -r "apiKey" ~/Library/Application\ Support/Cursor/User/
# HTH Guide Excerpt: end cli-verify-no-hardcoded-keys
