#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.2: Restrict Claude Code Permissions and Tools
# Profile: L2 | NIST: AC-3, CM-7 | SOC 2: CC6.1, CC6.3
# https://howtoharden.com/guides/anthropic-claude/#72-restrict-claude-code-permissions-and-tools
#
# Validates permission restrictions in managed-settings.json and provides
# example deny/allow/ask rule configurations.
source "$(dirname "$0")/common.sh"

banner "7.2: Restrict Claude Code Permissions and Tools"

# HTH Guide Excerpt: begin validate-permissions
# Validate permission configuration on this machine
MANAGED_PATH=""
case "$(uname -s)" in
  Darwin)  MANAGED_PATH="/Library/Application Support/ClaudeCode/managed-settings.json" ;;
  Linux)   MANAGED_PATH="/etc/claude-code/managed-settings.json" ;;
  MINGW*|MSYS*|CYGWIN*) MANAGED_PATH="C:\\Program Files\\ClaudeCode\\managed-settings.json" ;;
esac

if [[ -z "${MANAGED_PATH}" ]] || [[ ! -f "${MANAGED_PATH}" ]]; then
  warn "7.2 managed-settings.json not found — cannot validate permissions"
  summary; exit 0
fi

DENY_COUNT=$(jq '.permissions.deny // [] | length' "${MANAGED_PATH}" 2>/dev/null || echo 0)
ALLOW_COUNT=$(jq '.permissions.allow // [] | length' "${MANAGED_PATH}" 2>/dev/null || echo 0)
ASK_COUNT=$(jq '.permissions.ask // [] | length' "${MANAGED_PATH}" 2>/dev/null || echo 0)

info "Permission rules: deny=${DENY_COUNT}, allow=${ALLOW_COUNT}, ask=${ASK_COUNT}"

if [[ "${DENY_COUNT}" -gt 0 ]]; then
  pass "7.2 Deny rules configured (${DENY_COUNT} rules)"
else
  warn "7.2 No deny rules — sensitive files and commands are unrestricted"
fi

PERMS_ONLY=$(jq -r '.allowManagedPermissionRulesOnly // false' "${MANAGED_PATH}")
if [[ "${PERMS_ONLY}" == "true" ]]; then
  pass "7.2 Managed-only permission rules enforced"
else
  warn "7.2 allowManagedPermissionRulesOnly is not enabled — users can override rules"
fi

SANDBOX_ENABLED=$(jq -r '.sandbox.enabled // false' "${MANAGED_PATH}")
if [[ "${SANDBOX_ENABLED}" == "true" ]]; then
  pass "7.2 Bash sandbox is enabled"
  UNSANDBOXED=$(jq -r '.sandbox.allowUnsandboxedCommands // true' "${MANAGED_PATH}")
  if [[ "${UNSANDBOXED}" == "false" ]]; then
    pass "7.2 Unsandboxed command escape hatch is disabled"
  else
    warn "7.2 allowUnsandboxedCommands is true — users can bypass sandbox"
  fi
else
  info "7.2 Bash sandbox is not enabled (optional L3 control)"
fi
# HTH Guide Excerpt: end validate-permissions

summary
