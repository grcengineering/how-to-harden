#!/usr/bin/env bash
# HTH Cursor Control 4.1: Audit and Allowlist MCP Servers
# Profile: L1 | NIST: CM-7, SA-9
# https://howtoharden.com/guides/cursor/#41-audit-and-allowlist-mcp-servers

# HTH Guide Excerpt: begin cli-mcp-audit
# Audit all MCP server configurations across project and global scopes
echo "=== MCP Configuration Audit ==="

# Project-level MCP config
PROJECT_MCP=".cursor/mcp.json"
if [ -f "$PROJECT_MCP" ]; then
  echo "Project MCP config found: $PROJECT_MCP"
  echo "  Configured servers:"
  jq -r '.mcpServers // {} | keys[]' "$PROJECT_MCP" 2>/dev/null || echo "  (invalid JSON)"
  echo ""
  echo "  Full config (review for suspicious commands/URLs):"
  cat "$PROJECT_MCP"
else
  echo "No project-level MCP config found (OK)"
fi

echo ""

# Global MCP config
GLOBAL_MCP="${HOME}/.cursor/mcp.json"
if [ -f "$GLOBAL_MCP" ]; then
  echo "Global MCP config found: $GLOBAL_MCP"
  echo "  Configured servers:"
  jq -r '.mcpServers // {} | keys[]' "$GLOBAL_MCP" 2>/dev/null || echo "  (invalid JSON)"
  echo ""
  echo "  Full config (review for suspicious commands/URLs):"
  cat "$GLOBAL_MCP"
else
  echo "No global MCP config found (OK if MCP not used)"
fi

echo ""
echo "=== Review Checklist ==="
echo "  [ ] Every MCP server is from a trusted source"
echo "  [ ] No unexpected 'command' entries with curl, wget, or shell pipes"
echo "  [ ] No servers pointing to unknown URLs or IP addresses"
echo "  [ ] Config files are not writable by other users (check permissions)"
# HTH Guide Excerpt: end cli-mcp-audit

# HTH Guide Excerpt: begin cli-mcp-permissions
# Lock down MCP config file permissions to prevent unauthorized modification
echo "=== Securing MCP config file permissions ==="
for MCP_FILE in ".cursor/mcp.json" "${HOME}/.cursor/mcp.json"; do
  if [ -f "$MCP_FILE" ]; then
    chmod 600 "$MCP_FILE"
    echo "  Set $MCP_FILE to 600 (owner read/write only)"
  fi
done
# HTH Guide Excerpt: end cli-mcp-permissions
