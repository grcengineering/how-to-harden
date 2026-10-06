#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.1: Deploy Managed Settings via MDM
# Profile: L1 | NIST: CM-6, CM-7 | SOC 2: CC6.1, CC8.1
# https://howtoharden.com/guides/anthropic-claude/#71-deploy-managed-settings-via-mdm
#
# Validates the file-based managed settings on the local machine, evaluated the
# way Claude Code reads them: managed-settings.json merged with every
# managed-settings.d/*.json drop-in (alphabetical order; objects deep-merge,
# arrays concatenate and de-duplicate, later scalar values win).
# Reference: code.claude.com/docs/en/managed-settings
#
# Set HTH_CLAUDE_MANAGED_DIR to validate a staged policy directory (for example
# the repository that feeds your MDM) instead of this machine's system path.
# Exit code: 0 when every check passes, 1 when any check fails.
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
pass()  { printf "${GREEN}[PASS]${NC}  %s\n" "$*"; APPLIED=$((APPLIED+1)); }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; FAILED=$((FAILED+1)); }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; SKIPPED=$((SKIPPED+1)); }
APPLIED=0; FAILED=0; SKIPPED=0

banner() {
  echo ""
  printf "${BLUE}━━━ HTH Anthropic Claude: %s ━━━${NC}\n" "$1"
  echo ""
}

summary() {
  echo ""
  printf "${BLUE}──── Summary ────${NC}\n"
  printf "  Applied: ${GREEN}%d${NC}  Failed: ${RED}%d${NC}  Skipped: ${YELLOW}%d${NC}\n" \
    "${APPLIED}" "${FAILED}" "${SKIPPED}"
  echo ""
}

banner "7.1: Deploy Managed Settings via MDM"

# HTH Guide Excerpt: begin validate-managed-settings
# Locate the file-based managed settings directory for this OS
STAGED=0
if [[ -n "${HTH_CLAUDE_MANAGED_DIR:-}" ]]; then
  MANAGED_DIR="${HTH_CLAUDE_MANAGED_DIR}"; STAGED=1
else
  case "$(uname -s)" in
    Darwin) MANAGED_DIR="/Library/Application Support/ClaudeCode" ;;
    Linux)  MANAGED_DIR="/etc/claude-code" ;;
    MINGW*|MSYS*|CYGWIN*) MANAGED_DIR="C:/Program Files/ClaudeCode" ;;
    *)
      fail "7.1 Unknown OS — cannot locate the managed settings directory"
      summary; exit 1
      ;;
  esac
fi
info "Checking file-based managed settings in: ${MANAGED_DIR}"

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
  fail "7.1 No managed-settings.json or managed-settings.d/*.json found — file-based managed settings are not deployed"
  summary; exit 1
fi

# Claude Code refuses to start when a managed file is not a JSON object
for f in "${SOURCES[@]}"; do
  if jq -e 'type == "object"' "${f}" >/dev/null 2>&1; then
    pass "7.1 ${f} is a valid JSON object"
  else
    fail "7.1 ${f} is not a JSON object — Claude Code refuses to start when it cannot parse a managed file"
  fi
done
if [[ ${FAILED} -gt 0 ]]; then summary; exit 1; fi

# Merge the sources the way Claude Code does
MERGED=$(jq -s '
  def m($a; $b):
    if ($a|type) == "object" and ($b|type) == "object" then
      reduce ($b|keys[]) as $k ($a; .[$k] = m($a[$k]; $b[$k]))
    elif ($a|type) == "array" and ($b|type) == "array" then ($a + $b | unique)
    else $b end;
  reduce .[] as $x ({}; m(.; $x))' "${SOURCES[@]}")
merged() { printf '%s' "${MERGED}" | jq "$@"; }

# disableBypassPermissionsMode is read only under "permissions"; a root-level
# copy is accepted by the file but never applied
if [[ "$(merged -r 'has("disableBypassPermissionsMode")')" == "true" ]]; then
  fail "7.1 disableBypassPermissionsMode is at the root — Claude Code reads it only as permissions.disableBypassPermissionsMode"
fi

BYPASS=$(merged -r '.permissions.disableBypassPermissionsMode // "not set"')
DENY_COUNT=$(merged '.permissions.deny // [] | length')
DEFAULT_MODE=$(merged -r '.permissions.defaultMode // "not set"')
MANAGED_PERMS_ONLY=$(merged -r 'if .allowManagedPermissionRulesOnly == null then "not set" else .allowManagedPermissionRulesOnly end')

info "Merged policy (${#SOURCES[@]} file(s)):"
info "  permissions.disableBypassPermissionsMode: ${BYPASS}"
info "  permissions.deny rules: ${DENY_COUNT}"
info "  permissions.defaultMode: ${DEFAULT_MODE}"
info "  allowManagedPermissionRulesOnly: ${MANAGED_PERMS_ONLY}"

if [[ "${BYPASS}" == "disable" ]]; then
  pass "7.1 Bypass permissions mode is disabled"
else
  fail "7.1 permissions.disableBypassPermissionsMode is not \"disable\" — --dangerously-skip-permissions still works"
fi

if [[ "${DENY_COUNT}" -gt 0 ]]; then
  merged -r '.permissions.deny[]' | while IFS= read -r rule; do info "    - ${rule}"; done
  pass "7.1 Deny rules are configured (${DENY_COUNT} rules)"
else
  fail "7.1 No permissions.deny rules in the managed policy"
fi

if [[ "${DEFAULT_MODE}" == "not set" ]]; then
  warn "7.1 permissions.defaultMode is not set in the managed policy"
fi

if [[ "${MANAGED_PERMS_ONLY}" == "true" ]]; then
  pass "7.1 Only managed permission rules are enforced"
else
  warn "7.1 allowManagedPermissionRulesOnly is not enabled (see Control 7.2)"
fi

# Sources are first-wins by default: a higher-ranked source that carries any
# policy key is used and this file is skipped without a warning
if [[ ${STAGED} -eq 0 ]]; then
  if [[ -f "/Library/Managed Preferences/com.anthropic.claudecode.plist" ]]; then
    warn "7.1 An MDM profile (com.anthropic.claudecode) outranks this file — unless it sets managedSourcesBehavior: \"merge\", Claude Code skips the file"
  fi
  if command -v reg.exe >/dev/null 2>&1 && reg.exe query 'HKLM\SOFTWARE\Policies\ClaudeCode' >/dev/null 2>&1; then
    warn "7.1 An HKLM policy (SOFTWARE\\Policies\\ClaudeCode) outranks this file — unless it sets managedSourcesBehavior: \"merge\", Claude Code skips the file"
  fi
  info "Server-managed settings (claude.ai) also outrank this file; run /status in Claude Code and read the Setting sources line to confirm which source is in force"
fi
# HTH Guide Excerpt: end validate-managed-settings

summary
[[ ${FAILED} -eq 0 ]]
