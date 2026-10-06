#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-3.1
#   guide:   https://howtoharden.com/guides/cursor/#31-use-environment-variables-for-api-keys-never-hardcode
#   profile: L1
#   mode:    mutating
#   requires: an interactive terminal for the key prompt; HTH_SHELL_PROFILE(optional, default ~/.zshrc)
# =============================================================================
# HTH Cursor Control 3.1: Use Environment Variables for API Keys (Never Hardcode)
# Profile Level: L1 (Crawl) | NIST 800-53: IA-5(1)
# Source: https://howtoharden.com/guides/cursor/#31-use-environment-variables-for-api-keys-never-hardcode
#
# FIXED DEFECTS (validate-hth-guide, 2026-09-24):
#  - The setup excerpt used to append literal placeholders
#    (export OPENAI_API_KEY="sk-proj-YOUR-KEY-HERE") to ~/.zshrc on EVERY run
#    and then `source ~/.zshrc` from bash, so a real key already exported was
#    shadowed by the placeholder. It now prompts (input hidden), writes each
#    variable once, skips variables that are already defined, and never sources
#    a zsh file from bash.
#  - The git-history check used `grep -c ... || echo "0"`, which yields "0\n0"
#    on zero matches and breaks the integer test. The count is now taken once.
#
# Exit codes (verify excerpt): 0 no hardcoded or committed key found |
# 1 a key was found in a settings file or in git history
# =============================================================================

# HTH Guide Excerpt: begin cli-api-key-antipattern
# INSECURE: Never hardcode API keys in Cursor settings files
# This is an example of what to SEARCH FOR and REMOVE:
#   "cursor.openai.apiKey": "sk-proj-abc123..."
#   "cursor.anthropic.apiKey": "sk-ant-abc123..."
# HTH Guide Excerpt: end cli-api-key-antipattern

# HTH Guide Excerpt: begin cli-api-key-env-setup
# Add provider keys to your shell profile once, without echoing them.
PROFILE="${HTH_SHELL_PROFILE:-${HOME}/.zshrc}"
touch "$PROFILE"
for VAR in OPENAI_API_KEY ANTHROPIC_API_KEY; do
  if grep -q "^export ${VAR}=" "$PROFILE"; then
    echo "  SKIP: ${VAR} is already defined in ${PROFILE} (rotate it with the 3.2 pack)"
    continue
  fi
  printf 'Enter %s (input hidden; leave empty to skip): ' "$VAR"
  IFS= read -rs VALUE
  echo
  if [ -z "$VALUE" ]; then
    echo "  SKIP: no value entered for ${VAR}"
    continue
  fi
  printf 'export %s=%q\n' "$VAR" "$VALUE" >> "$PROFILE"
  unset VALUE
  echo "  ADDED: ${VAR} to ${PROFILE}"
done
echo "Open a new terminal (and restart Cursor) to load the variables."
# HTH Guide Excerpt: end cli-api-key-env-setup

# HTH Guide Excerpt: begin cli-api-key-verify
# Verify no hardcoded API keys exist in Cursor settings files or git history
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
LEAKED=0
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
  LEAKED=$(git log --all -p 2>/dev/null | grep -cE '(sk-proj-|sk-ant-)[A-Za-z0-9_-]{20,}')
  LEAKED=${LEAKED:-0}
  if [ "$LEAKED" -gt 0 ]; then
    echo "  FAIL: $LEAKED potential API key(s) found in git history"
    echo "  ACTION: Rotate keys immediately and use git-filter-repo to purge"
  else
    echo "  PASS: No API keys found in git history"
  fi
else
  echo "  SKIP: not inside a git work tree"
fi

[ "$FOUND" -eq 0 ] && [ "$LEAKED" -eq 0 ] || exit 1
# HTH Guide Excerpt: end cli-api-key-verify
