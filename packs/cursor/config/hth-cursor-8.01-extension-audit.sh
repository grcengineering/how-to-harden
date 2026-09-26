#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-8.1
#   guide:   https://howtoharden.com/guides/cursor/#81-audit-and-restrict-vscode-extensions
#   profile: L1
#   mode:    read-only
#   requires: cursor CLI shim or jq (reads ~/.cursor/extensions/extensions.json)
# =============================================================================
# HTH Cursor Control 8.1: Audit and Restrict VSCode Extensions
# Profile Level: L1 (Crawl) | NIST 800-53: CM-7
# Source: https://howtoharden.com/guides/cursor/#81-audit-and-restrict-vscode-extensions
#
# Two inventory sources, in order: the `cursor` shell command (the VS Code-style
# CLI shim, which supports --list-extensions), then the VS Code-format extension
# manifest found on disk at ~/.cursor/extensions/extensions.json. The manifest is
# an internal file observed on real installs, not a documented interface —
# prefer the CLI where it exists. The CLI's output is used only when it exits 0;
# a CLI that fails falls back to the manifest. If neither source works the pack
# says so and exits 2: an audit that listed nothing is not a clean audit.
#
# Exit codes: 0 inventory produced | 2 no inventory source (including a cursor
# CLI that failed with no manifest to fall back to)
# =============================================================================

# HTH Guide Excerpt: begin cli-extension-audit
# List every installed extension with its version
echo "=== Installed Extension Audit ==="
EXT_MANIFEST="${HOME}/.cursor/extensions/extensions.json"
CLI_RC="absent"
if command -v cursor &>/dev/null; then
  # Capture first, trust only on exit 0 — a failing CLI prints nothing, and
  # "nothing" must not read as "zero extensions installed".
  EXT_LIST=$(cursor --list-extensions --show-versions 2>/dev/null); CLI_RC=$?
fi
if [ "$CLI_RC" = "0" ]; then
  echo "Source: cursor --list-extensions"
  printf '%s\n' "$EXT_LIST" | sed '/^[[:space:]]*$/d; s/^/  /'
  TOTAL=$(printf '%s\n' "$EXT_LIST" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
elif [ -f "$EXT_MANIFEST" ] && command -v jq &>/dev/null; then
  if [ "$CLI_RC" = "absent" ]; then
    echo "Source: $EXT_MANIFEST (cursor CLI not on PATH)"
  else
    echo "Source: $EXT_MANIFEST (cursor --list-extensions failed with exit $CLI_RC)"
  fi
  if ! jq -e 'type == "array"' "$EXT_MANIFEST" >/dev/null 2>&1; then
    echo "ERROR: $EXT_MANIFEST is not a JSON array — cannot inventory extensions"
    exit 2
  fi
  jq -r '.[] | "  \(.identifier.id)@\(.version)"' "$EXT_MANIFEST"
  TOTAL=$(jq 'length' "$EXT_MANIFEST")
else
  if [ "$CLI_RC" = "absent" ]; then
    echo "ERROR: no extension inventory source found"
  else
    echo "ERROR: cursor --list-extensions failed (exit $CLI_RC) and there is no manifest to fall back to — nothing was inventoried"
  fi
  echo "  Put a working 'cursor' shell command on PATH, or run this where $EXT_MANIFEST exists and jq is installed."
  exit 2
fi
echo ""
echo "Total extensions: $TOTAL"

echo ""
echo "=== Extension Risk Checklist ==="
echo "  [ ] Remove extensions not updated in >1 year"
echo "  [ ] Remove extensions with <10K installs (less vetted)"
echo "  [ ] Verify publisher identity for all security-relevant extensions"
echo "  [ ] Check that no extensions were side-loaded from .vsix files"
echo "  [ ] Confirm extensions come from Open VSX with verified publishers"
# HTH Guide Excerpt: end cli-extension-audit
