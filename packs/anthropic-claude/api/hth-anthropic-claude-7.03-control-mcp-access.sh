#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.3: Control MCP Server Access
# Profile: L2 | NIST: CM-7, SA-9 | SOC 2: CC6.6, CC9.2
# https://howtoharden.com/guides/anthropic-claude/#73-control-mcp-server-access
#
# Validates MCP server restrictions and provides example configurations.
# MCP servers extend Claude Code with additional tools — uncontrolled
# servers can introduce arbitrary access to databases, APIs, and cloud.
source "$(dirname "$0")/common.sh"

banner "7.3: Control MCP Server Access"

# HTH Guide Excerpt: begin validate-mcp-access
# Validate MCP configuration on this machine
MCP_PATH=""
MANAGED_PATH=""
case "$(uname -s)" in
  Darwin)
    MCP_PATH="/Library/Application Support/ClaudeCode/managed-mcp.json"
    MANAGED_PATH="/Library/Application Support/ClaudeCode/managed-settings.json"
    ;;
  Linux)
    MCP_PATH="/etc/claude-code/managed-mcp.json"
    MANAGED_PATH="/etc/claude-code/managed-settings.json"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    MCP_PATH="C:\\Program Files\\ClaudeCode\\managed-mcp.json"
    MANAGED_PATH="C:\\Program Files\\ClaudeCode\\managed-settings.json"
    ;;
esac

# Check for managed-mcp.json (exclusive control)
if [[ -n "${MCP_PATH}" ]] && [[ -f "${MCP_PATH}" ]]; then
  if jq empty "${MCP_PATH}" 2>/dev/null; then
    SERVER_COUNT=$(jq '.mcpServers | length' "${MCP_PATH}" 2>/dev/null || echo 0)
    pass "7.3 managed-mcp.json deployed — ${SERVER_COUNT} approved MCP servers"
    info "Approved servers:"
    jq -r '.mcpServers | keys[]' "${MCP_PATH}" 2>/dev/null | while read -r server; do
      info "  - ${server}"
    done
  else
    fail "7.3 managed-mcp.json exists but is not valid JSON"
  fi
else
  info "7.3 No managed-mcp.json — checking allowlist/denylist in managed settings"
fi

# Check allowlist/denylist in managed-settings.json
if [[ -n "${MANAGED_PATH}" ]] && [[ -f "${MANAGED_PATH}" ]]; then
  ALLOWED=$(jq '.allowedMcpServers // [] | length' "${MANAGED_PATH}" 2>/dev/null || echo 0)
  DENIED=$(jq '.deniedMcpServers // [] | length' "${MANAGED_PATH}" 2>/dev/null || echo 0)

  if [[ "${ALLOWED}" -gt 0 ]] || [[ "${DENIED}" -gt 0 ]]; then
    info "MCP allowlist: ${ALLOWED} servers, denylist: ${DENIED} servers"
    if [[ "${DENIED}" -gt 0 ]]; then
      pass "7.3 MCP deny rules configured (${DENIED} servers blocked)"
    fi
    if [[ "${ALLOWED}" -gt 0 ]]; then
      pass "7.3 MCP allowlist configured (${ALLOWED} servers approved)"
    fi
  else
    warn "7.3 No MCP allowlist or denylist — all MCP servers are permitted"
  fi

  AUTO_APPROVE=$(jq -r '.enableAllProjectMcpServers // "not set"' "${MANAGED_PATH}")
  if [[ "${AUTO_APPROVE}" == "true" ]]; then
    warn "7.3 enableAllProjectMcpServers is true — project MCP servers auto-approved"
  elif [[ "${AUTO_APPROVE}" == "false" ]]; then
    pass "7.3 Project MCP servers require explicit approval"
  fi
fi
# HTH Guide Excerpt: end validate-mcp-access

summary
