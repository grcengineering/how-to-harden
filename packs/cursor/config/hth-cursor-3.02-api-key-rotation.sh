#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-3.2
#   guide:   https://howtoharden.com/guides/cursor/#32-rotate-ai-provider-api-keys-quarterly
#   profile: L2
#   mode:    mutating
#   requires: perl, an interactive terminal for the key prompt; HTH_SHELL_PROFILE(optional, default ~/.zshrc)
# =============================================================================
# HTH Cursor Control 3.2: Rotate AI Provider API Keys Quarterly
# Profile Level: L2 (Walk) | NIST 800-53: IA-5(1)
# Source: https://howtoharden.com/guides/cursor/#32-rotate-ai-provider-api-keys-quarterly
#
# Usage: bash hth-cursor-3.02-api-key-rotation.sh [OPENAI_API_KEY|ANTHROPIC_API_KEY]
#
# FIXED DEFECT (validate-hth-guide, 2026-09-24): the previous version ran
#   sed -i '' 's|^export OPENAI_API_KEY=.*|export OPENAI_API_KEY="sk-proj-NEW-KEY-HERE"|'
# which REPLACED the operator's working key with a literal placeholder — run as
# written, it broke the key it claimed to rotate. `sed -i ''` is also BSD-only,
# and the script sourced a zsh profile from bash. The new key is now read at run
# time (hidden), validated, and written with a portable in-place edit.
#
# Exit codes: 0 rotated | 2 precondition (unknown variable, variable not in the
# profile yet, empty or malformed key)
# =============================================================================

# HTH Guide Excerpt: begin cli-key-rotation
# Replace the key in your shell profile with a newly minted one (input hidden).
VAR="${1:-OPENAI_API_KEY}"
PROFILE="${HTH_SHELL_PROFILE:-${HOME}/.zshrc}"
case "$VAR" in
  OPENAI_API_KEY|ANTHROPIC_API_KEY) ;;
  *) echo "ERROR: unsupported variable '$VAR' (use OPENAI_API_KEY or ANTHROPIC_API_KEY)"; exit 2 ;;
esac
if ! grep -q "^export ${VAR}=" "$PROFILE" 2>/dev/null; then
  echo "ERROR: ${VAR} is not defined in ${PROFILE} — add it first with the 3.1 pack"
  exit 2
fi
printf 'Paste the NEW %s (input hidden): ' "$VAR"
IFS= read -rs NEW_KEY
echo
if [ -z "$NEW_KEY" ]; then
  echo "ERROR: no key entered — ${PROFILE} left unchanged"
  exit 2
fi
case "$NEW_KEY" in
  *[!A-Za-z0-9._-]*) echo "ERROR: key contains unexpected characters — ${PROFILE} left unchanged"; exit 2 ;;
esac
VAR="$VAR" NEW_KEY="$NEW_KEY" perl -pi -e 's/^export \Q$ENV{VAR}\E=.*/export $ENV{VAR}="$ENV{NEW_KEY}"/' "$PROFILE"
unset NEW_KEY
echo "${VAR} rotated in ${PROFILE}. Open a new terminal, restart Cursor, confirm the new key works,"
echo "then REVOKE the old key in the provider console."
# HTH Guide Excerpt: end cli-key-rotation
