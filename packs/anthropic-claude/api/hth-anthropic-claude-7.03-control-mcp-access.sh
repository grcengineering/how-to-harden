#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.3: Control MCP Server Access
# Profile: L2 | NIST: CM-7, SA-9 | SOC 2: CC6.6, CC9.2
# https://howtoharden.com/guides/anthropic-claude/#73-control-mcp-server-access
#
# Validates MCP server restrictions: managed-mcp.json (exclusive control) and
# the allowlist/denylist in the file-based managed settings (managed-settings.json
# merged with managed-settings.d/*.json). MCP servers extend Claude Code with
# additional tools — uncontrolled servers can introduce arbitrary access to
# databases, APIs, and cloud. Reference: code.claude.com/docs/en/managed-mcp
# Set HTH_CLAUDE_MANAGED_DIR to validate a staged policy directory instead of
# this machine's system path.
# Exit code: 0 when MCP access is controlled, 1 otherwise.
source "$(dirname "$0")/common.sh"

banner "7.3: Control MCP Server Access"

# HTH Guide Excerpt: begin validate-mcp-access
# Validate MCP configuration on this machine
if [[ -n "${HTH_CLAUDE_MANAGED_DIR:-}" ]]; then
  MANAGED_DIR="${HTH_CLAUDE_MANAGED_DIR}"
else
  case "$(uname -s)" in
    Darwin) MANAGED_DIR="/Library/Application Support/ClaudeCode" ;;
    Linux)  MANAGED_DIR="/etc/claude-code" ;;
    MINGW*|MSYS*|CYGWIN*) MANAGED_DIR="C:/Program Files/ClaudeCode" ;;
    *) fail "7.3 Unknown OS — cannot locate the managed settings directory"; summary; exit 1 ;;
  esac
fi

# managed-mcp.json takes exclusive control: users cannot add other servers
EXCLUSIVE=0
MCP_PATH="${MANAGED_DIR}/managed-mcp.json"
if [[ -f "${MCP_PATH}" ]]; then
  if jq -e '(.mcpServers | type) == "object"' "${MCP_PATH}" >/dev/null 2>&1; then
    EXCLUSIVE=1
    SERVER_COUNT=$(jq '.mcpServers | length' "${MCP_PATH}")
    pass "7.3 managed-mcp.json deployed — exclusive control, ${SERVER_COUNT} approved MCP servers"
    jq -r '.mcpServers | keys[]' "${MCP_PATH}" | while IFS= read -r server; do info "  - ${server}"; done
  else
    fail "7.3 managed-mcp.json exists but is not a JSON object with an mcpServers map"
  fi
else
  info "7.3 No managed-mcp.json — checking the allowlist/denylist in managed settings"
fi

# Managed settings: base file first, then drop-ins in alphabetical order
SOURCES=()
if [[ -f "${MANAGED_DIR}/managed-settings.json" ]]; then
  SOURCES+=("${MANAGED_DIR}/managed-settings.json")
fi
LC_COLLATE=C
for f in "${MANAGED_DIR}/managed-settings.d/"*.json; do
  if [[ -f "${f}" ]]; then SOURCES+=("${f}"); fi
done

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  if [[ ${EXCLUSIVE} -eq 1 ]]; then
    info "7.3 No managed settings file — MCP is governed by managed-mcp.json alone"
  else
    fail "7.3 No managed-mcp.json and no managed settings — MCP is uncontrolled"
  fi
  summary
  if [[ ${FAILED} -eq 0 ]]; then exit 0; fi
  exit 1
fi

MERGED=$(jq -s '
  def m($a; $b):
    if ($a|type) == "object" and ($b|type) == "object" then
      reduce ($b|keys[]) as $k ($a; .[$k] = m($a[$k]; $b[$k]))
    elif ($a|type) == "array" and ($b|type) == "array" then ($a + $b | unique)
    else $b end;
  reduce .[] as $x ({}; m(.; $x))' "${SOURCES[@]}") || {
  fail "7.3 A managed settings file is not valid JSON"; summary; exit 1
}
merged() { printf '%s' "${MERGED}" | jq "$@"; }

ALLOWED=$(merged '.allowedMcpServers // [] | length')
DENIED=$(merged '.deniedMcpServers // [] | length')
LOCKED=$(merged -r '.allowManagedMcpServersOnly // false')
info "MCP allowlist: ${ALLOWED} servers, denylist: ${DENIED} servers, allowManagedMcpServersOnly: ${LOCKED}"

if [[ ${EXCLUSIVE} -eq 0 ]] && [[ "${ALLOWED}" -eq 0 ]] && [[ "${DENIED}" -eq 0 ]]; then
  fail "7.3 No managed-mcp.json, allowlist, or denylist — all MCP servers are permitted"
fi

if [[ "${DENIED}" -gt 0 ]]; then
  pass "7.3 MCP deny rules configured (${DENIED} servers blocked)"
fi

if [[ "${ALLOWED}" -gt 0 ]]; then
  if [[ "${LOCKED}" == "true" ]]; then
    pass "7.3 MCP allowlist configured and authoritative (${ALLOWED} servers approved)"
  elif [[ ${EXCLUSIVE} -eq 1 ]]; then
    info "7.3 allowedMcpServers is set without allowManagedMcpServersOnly; managed-mcp.json still holds exclusive control"
  else
    fail "7.3 MCP allowlist is soft — without allowManagedMcpServersOnly: true, users can broaden it in ~/.claude/settings.json"
  fi
elif [[ "${DENIED}" -gt 0 ]] && [[ ${EXCLUSIVE} -eq 0 ]]; then
  warn "7.3 Denylist only — any MCP server not on the denylist is permitted"
fi

if [[ "${LOCKED}" == "true" ]] && [[ "${ALLOWED}" -eq 0 ]] && [[ ${EXCLUSIVE} -eq 0 ]]; then
  warn "7.3 allowManagedMcpServersOnly is true but no managed allowedMcpServers list was found in these files"
fi

# jq's // treats false as missing, so read the boolean explicitly
AUTO_APPROVE=$(merged -r 'if .enableAllProjectMcpServers == null then "not set" else .enableAllProjectMcpServers end')
if [[ "${AUTO_APPROVE}" == "true" ]]; then
  warn "7.3 enableAllProjectMcpServers is true — project MCP servers auto-approved"
elif [[ "${AUTO_APPROVE}" == "false" ]]; then
  pass "7.3 Project MCP servers require explicit approval"
fi
# HTH Guide Excerpt: end validate-mcp-access

summary
[[ ${FAILED} -eq 0 ]]
