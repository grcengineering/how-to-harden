#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-4.1
#   guide:   https://howtoharden.com/guides/cursor/#41-audit-and-allowlist-mcp-servers
#   profile: L1
#   mode:    mutating
#   requires: jq
# =============================================================================
# HTH Cursor Control 4.1: Audit and Allowlist MCP Servers
# Profile Level: L1 (Crawl) | NIST 800-53: CM-7, SA-9
# Source: https://howtoharden.com/guides/cursor/#41-audit-and-allowlist-mcp-servers
#
# Default invocation is a read-only audit. `--fix` additionally runs the
# permissions excerpt (chmod 600) — the only mutation, and the reason the pack
# as a whole declares `mutating`.
#
# FIXED DEFECT (validate-hth-guide, 2026-09-24): the audit used to `cat` both
# mcp.json files in full. MCP server entries routinely carry tokens in their
# `env` and `headers` blocks, so the "audit" copied secrets into the terminal
# and into any CI log that captured it. It now prints each server's command,
# URL and argument list with secret-looking arguments redacted, and only the
# NAMES of env variables and headers — enough to review, never the values.
# Tool-level pre-approval (`mcpAllowlist` in permissions.json) is audited by the
# 4.2 pack.
#
# Exit codes: 0 no finding | 1 finding | 2 jq missing or a config file that
# does not parse
# =============================================================================

command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin cli-mcp-audit
# Audit every MCP server in the project and global configs — without printing secrets
echo "=== MCP Configuration Audit ==="
FINDINGS=0
for MCP_FILE in ".cursor/mcp.json" "${HOME}/.cursor/mcp.json"; do
  if [ ! -f "$MCP_FILE" ]; then
    echo "No MCP config at $MCP_FILE"
    continue
  fi
  if ! jq -e . "$MCP_FILE" >/dev/null 2>&1; then
    echo "ERROR: $MCP_FILE is not valid JSON"
    exit 2
  fi
  echo "--- $MCP_FILE ---"
  jq -r '
    (.mcpServers // {}) | to_entries[] |
    "  server: \(.key)",
    "    command: \(.value.command // "-")",
    "    args:    \((.value.args // []) | map(tostring | if test("(?i)(token|secret|passw|bearer|api[_-]?key|auth)") then "<redacted>" else . end) | join(" "))",
    "    url:     \(.value.url // "-")",
    "    env var names:  \((.value.env // {}) | keys | join(", "))",
    "    header names:   \((.value.headers // {}) | keys | join(", "))"' "$MCP_FILE"
  # Flag launch commands that fetch-and-run, and remote servers over cleartext HTTP
  RISKY=$(jq -r '(.mcpServers // {}) | to_entries[]
    | select(((.value.command // "") + " " + ((.value.args // []) | join(" ")))
             | test("curl|wget|bash -c|sh -c|\\| *(ba)?sh"))
    | .key' "$MCP_FILE")
  CLEAR=$(jq -r '(.mcpServers // {}) | to_entries[] | select((.value.url // "") | startswith("http://")) | .key' "$MCP_FILE")
  for S in $RISKY; do echo "  FINDING: server '$S' launches through a download or shell pipe"; FINDINGS=$((FINDINGS + 1)); done
  for S in $CLEAR; do echo "  FINDING: server '$S' uses a cleartext http:// URL"; FINDINGS=$((FINDINGS + 1)); done
  if [[ "$OSTYPE" == darwin* ]]; then PERMS=$(stat -f '%Lp' "$MCP_FILE"); else PERMS=$(stat -c '%a' "$MCP_FILE"); fi
  case "$PERMS" in
    ??[2367]|?[2367]?) echo "  FINDING: $MCP_FILE is writable by group or others (mode $PERMS)"; FINDINGS=$((FINDINGS + 1)) ;;
  esac
done

echo ""
echo "=== Review Checklist ==="
echo "  [ ] Every MCP server is from a trusted source"
echo "  [ ] Secrets named above live in a secret manager or env injection, not in mcp.json"
echo "  [ ] Tool pre-approvals reviewed with the 4.2 pack (permissions.json mcpAllowlist)"
# HTH Guide Excerpt: end cli-mcp-audit

# HTH Guide Excerpt: begin cli-mcp-permissions
# MUTATING, only with --fix: lock MCP config files to owner read/write
if [ "${1:-}" = "--fix" ]; then
  echo "=== Securing MCP config file permissions ==="
  for MCP_FILE in ".cursor/mcp.json" "${HOME}/.cursor/mcp.json"; do
    if [ -f "$MCP_FILE" ]; then
      chmod 600 "$MCP_FILE"
      echo "  Set $MCP_FILE to 600 (owner read/write only)"
    fi
  done
fi
# HTH Guide Excerpt: end cli-mcp-permissions

[ "$FINDINGS" -eq 0 ] || { echo "$FINDINGS finding(s)"; exit 1; }
exit 0
