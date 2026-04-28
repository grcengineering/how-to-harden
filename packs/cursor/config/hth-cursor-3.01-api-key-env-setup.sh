#!/usr/bin/env bash
# HTH Cursor Control 3.1: Use Environment Variables for API Keys
# Profile: L1 | NIST: IA-5(1)
# https://howtoharden.com/guides/cursor/#31-use-environment-variables-for-api-keys

# HTH Guide Excerpt: begin cli-api-key-antipattern
# INSECURE: Never hardcode API keys in Cursor settings files
# This is an example of what to SEARCH FOR and REMOVE:
#   "cursor.openai.apiKey": "sk-proj-abc123..."
#   "cursor.anthropic.apiKey": "sk-ant-abc123..."
# HTH Guide Excerpt: end cli-api-key-antipattern

# HTH Guide Excerpt: begin cli-api-key-env-setup
# Add API keys as environment variables in your shell profile
# For zsh (default on macOS):
cat >> ~/.zshrc <<'ENVVARS'

# Cursor AI Provider API Keys (rotate quarterly — see HTH 3.2)
export OPENAI_API_KEY="sk-proj-YOUR-KEY-HERE"
export ANTHROPIC_API_KEY="sk-ant-YOUR-KEY-HERE"
ENVVARS

source ~/.zshrc
echo "API keys added to ~/.zshrc as environment variables"
# HTH Guide Excerpt: end cli-api-key-env-setup

# HTH Guide Excerpt: begin cli-api-key-verify
# Verify no hardcoded API keys exist in Cursor settings files
echo "=== Scanning for hardcoded API keys in Cursor settings ==="
SETTINGS_PATHS=(
  "${HOME}/Library/Application Support/Cursor/User/settings.json"
  "${HOME}/.config/Cursor/User/settings.json"
  ".vscode/settings.json"
)

FOUND=0
for f in "${SETTINGS_PATHS[@]}"; do
  if [ -f "$f" ]; then
    if grep -qE '(sk-proj-|sk-ant-|OPENAI_API_KEY|ANTHROPIC_API_KEY)' "$f" 2>/dev/null; then
      echo "  FAIL: Hardcoded key found in $f"
      FOUND=$((FOUND + 1))
    fi
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "  PASS: No hardcoded API keys found in settings files"
fi

# Also check git history for accidentally committed keys
echo ""
echo "=== Checking git history for leaked keys ==="
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
  LEAKED=$(git log --all -p 2>/dev/null | grep -cE '(sk-proj-|sk-ant-)[A-Za-z0-9]{20,}' || echo "0")
  if [ "$LEAKED" -gt 0 ]; then
    echo "  FAIL: $LEAKED potential API key(s) found in git history"
    echo "  ACTION: Rotate keys immediately and use git-filter-repo to purge"
  else
    echo "  PASS: No API keys found in git history"
  fi
fi
# HTH Guide Excerpt: end cli-api-key-verify
