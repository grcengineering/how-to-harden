#!/usr/bin/env bash
# HTH Cursor Control 2.03: Enable Local AI Models (L3 Maximum Security)
# Profile: L3 | NIST: SC-4, SC-7
# https://howtoharden.com/guides/cursor/#23-enable-local-ai-models-l3-maximum-security

set -euo pipefail

# --------------------------------------------------------------------------
# Step 1: Install and configure Ollama as local model backend
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-install-local-model
# Install Ollama local LLM runtime
brew install ollama  # macOS
# or download from https://ollama.ai

# Pull code model
ollama pull codellama:13b

# Start Ollama server (runs on localhost:11434)
ollama serve
# HTH Guide Excerpt: end cli-install-local-model

# --------------------------------------------------------------------------
# Step 2: Configure Cursor to use local model exclusively
# Apply to: ~/Library/Application Support/Cursor/User/settings.json (macOS)
#           %APPDATA%\Cursor\User\settings.json (Windows)
#           ~/.config/Cursor/User/settings.json (Linux)
# --------------------------------------------------------------------------

# HTH Guide Excerpt: begin cli-configure-local-model
# Point Cursor at local Ollama and disable all cloud providers
CURSOR_SETTINGS_DIR="${HOME}/Library/Application Support/Cursor/User"
SETTINGS_FILE="${CURSOR_SETTINGS_DIR}/settings.json"

jq '. + {
  "cursor.aiProviders.custom": [
    {
      "name": "Local Ollama",
      "endpoint": "http://localhost:11434/v1",
      "model": "codellama",
      "type": "openai-compatible"
    }
  ],
  "cursor.aiProviders.openai.enabled": false,
  "cursor.aiProviders.anthropic.enabled": false
}' "${SETTINGS_FILE}" > "${SETTINGS_FILE}.tmp" \
  && mv "${SETTINGS_FILE}.tmp" "${SETTINGS_FILE}"

echo "Cursor configured to use local Ollama model only"
# HTH Guide Excerpt: end cli-configure-local-model
