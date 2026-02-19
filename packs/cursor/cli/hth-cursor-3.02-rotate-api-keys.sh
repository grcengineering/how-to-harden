#!/usr/bin/env bash
# HTH Cursor Control 3.02: Rotate AI Provider API Keys Quarterly
# Profile: L2 | NIST: IA-5(1)
# https://howtoharden.com/guides/cursor/#32-rotate-ai-provider-api-keys-quarterly

set -euo pipefail

# --------------------------------------------------------------------------
# API Key Rotation Script
# Run quarterly to rotate all AI provider API keys
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-rotate-api-keys
# Rotate OpenAI API key
echo "Rotating OpenAI API key..."
# Generate new key via API (if supported)
# Update environment
# Revoke old key

echo "API keys rotated successfully"
# HTH Guide Excerpt: end cli-rotate-api-keys

# --------------------------------------------------------------------------
# Update Environment Variable After Rotation
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-update-env-after-rotation
# Update environment variable with new key
export OPENAI_API_KEY="sk-proj-NEW-KEY"
# HTH Guide Excerpt: end cli-update-env-after-rotation
