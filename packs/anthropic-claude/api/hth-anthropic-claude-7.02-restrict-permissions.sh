#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.2: Restrict Claude Code Permissions and Tools
# Profile: L2 | NIST: AC-3, CM-7 | SOC 2: CC6.1, CC6.3
# https://howtoharden.com/guides/anthropic-claude/#72-restrict-claude-code-permissions-and-tools
#
# Validates the permission restrictions in the file-based managed settings
# (managed-settings.json merged with managed-settings.d/*.json drop-ins, the
# way Claude Code merges them). Set HTH_CLAUDE_MANAGED_DIR to validate a
# staged policy directory instead of this machine's system path.
# Exit code: 0 when every required check passes, 1 when any check fails.
source "$(dirname "$0")/common.sh"

banner "7.2: Restrict Claude Code Permissions and Tools"

# HTH Guide Excerpt: begin validate-permissions
# Validate permission configuration on this machine
if [[ -n "${HTH_CLAUDE_MANAGED_DIR:-}" ]]; then
  MANAGED_DIR="${HTH_CLAUDE_MANAGED_DIR}"
else
  case "$(uname -s)" in
    Darwin)  MANAGED_DIR="/Library/Application Support/ClaudeCode" ;;
    Linux)   MANAGED_DIR="/etc/claude-code" ;;
    MINGW*|MSYS*|CYGWIN*) MANAGED_DIR="C:/Program Files/ClaudeCode" ;;
    *) fail "7.2 Unknown OS — cannot locate the managed settings directory"; summary; exit 1 ;;
  esac
fi

# Base file first, then drop-ins in alphabetical order (hidden files ignored)
SOURCES=()
if [[ -f "${MANAGED_DIR}/managed-settings.json" ]]; then
  SOURCES+=("${MANAGED_DIR}/managed-settings.json")
fi
LC_COLLATE=C
for f in "${MANAGED_DIR}/managed-settings.d/"*.json; do
  if [[ -f "${f}" ]]; then SOURCES+=("${f}"); fi
done

if [[ ${#SOURCES[@]} -eq 0 ]]; then
  fail "7.2 No managed-settings.json or managed-settings.d/*.json in ${MANAGED_DIR} — permissions are not restricted by managed policy"
  summary; exit 1
fi

MERGED=$(jq -s '
  def m($a; $b):
    if ($a|type) == "object" and ($b|type) == "object" then
      reduce ($b|keys[]) as $k ($a; .[$k] = m($a[$k]; $b[$k]))
    elif ($a|type) == "array" and ($b|type) == "array" then ($a + $b | unique)
    else $b end;
  reduce .[] as $x ({}; m(.; $x))' "${SOURCES[@]}") || {
  fail "7.2 A managed settings file is not valid JSON"; summary; exit 1
}
merged() { printf '%s' "${MERGED}" | jq "$@"; }

DENY_COUNT=$(merged '.permissions.deny // [] | length')
ALLOW_COUNT=$(merged '.permissions.allow // [] | length')
ASK_COUNT=$(merged '.permissions.ask // [] | length')
info "Permission rules across ${#SOURCES[@]} file(s): deny=${DENY_COUNT}, allow=${ALLOW_COUNT}, ask=${ASK_COUNT}"

if [[ "${DENY_COUNT}" -gt 0 ]]; then
  pass "7.2 Deny rules configured (${DENY_COUNT} rules)"
else
  fail "7.2 No deny rules — sensitive files and commands are unrestricted"
fi

PERMS_ONLY=$(merged -r '.allowManagedPermissionRulesOnly // false')
if [[ "${PERMS_ONLY}" == "true" ]]; then
  pass "7.2 Managed-only permission rules enforced"
else
  fail "7.2 allowManagedPermissionRulesOnly is not enabled — users can add their own allow rules"
fi

# Step 2.3: bypass mode must be disabled inside the permissions object
if [[ "$(merged -r 'has("disableBypassPermissionsMode")')" == "true" ]]; then
  fail "7.2 disableBypassPermissionsMode is at the root — Claude Code reads it only as permissions.disableBypassPermissionsMode"
fi
BYPASS=$(merged -r '.permissions.disableBypassPermissionsMode // "not set"')
if [[ "${BYPASS}" == "disable" ]]; then
  pass "7.2 Bypass permissions mode is disabled"
else
  fail "7.2 permissions.disableBypassPermissionsMode is not \"disable\""
fi

SANDBOX_ENABLED=$(merged -r '.sandbox.enabled // false')
if [[ "${SANDBOX_ENABLED}" == "true" ]]; then
  pass "7.2 Bash sandbox is enabled"
  # jq's // treats false as missing, so read the boolean explicitly (default: true)
  UNSANDBOXED=$(merged -r 'if .sandbox.allowUnsandboxedCommands == null then true else .sandbox.allowUnsandboxedCommands end')
  if [[ "${UNSANDBOXED}" == "false" ]]; then
    pass "7.2 Unsandboxed command escape hatch is disabled"
  else
    warn "7.2 sandbox.allowUnsandboxedCommands is not false — users can bypass the sandbox"
  fi
else
  info "7.2 Bash sandbox is not enabled (optional L3 control)"
fi
# HTH Guide Excerpt: end validate-permissions

summary
[[ ${FAILED} -eq 0 ]]
