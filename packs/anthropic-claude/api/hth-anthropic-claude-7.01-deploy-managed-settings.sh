#!/usr/bin/env bash
# HTH Anthropic Claude Control 7.1: Deploy Managed Settings via MDM
# Profile: L1 | NIST: CM-6, CM-7 | SOC 2: CC6.1, CC8.1
# https://howtoharden.com/guides/anthropic-claude/#71-deploy-managed-settings-via-mdm
#
# Validates that managed-settings.json is deployed and contains
# required security settings on the local machine.
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
# Detect OS and check for managed-settings.json in the correct path
case "$(uname -s)" in
  Darwin)
    MANAGED_PATH="/Library/Application Support/ClaudeCode/managed-settings.json"
    ;;
  Linux)
    MANAGED_PATH="/etc/claude-code/managed-settings.json"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    MANAGED_PATH="C:\\Program Files\\ClaudeCode\\managed-settings.json"
    ;;
  *)
    warn "7.1 Unknown OS — cannot determine managed-settings.json path"
    summary; exit 0
    ;;
esac

info "Checking for managed-settings.json at: ${MANAGED_PATH}"

if [[ ! -f "${MANAGED_PATH}" ]]; then
  fail "7.1 managed-settings.json not found — MDM deployment may not be configured"
  summary; exit 0
fi

pass "7.1 managed-settings.json exists at ${MANAGED_PATH}"

# Validate JSON structure
if ! jq empty "${MANAGED_PATH}" 2>/dev/null; then
  fail "7.1 managed-settings.json is not valid JSON"
  summary; exit 0
fi

pass "7.1 managed-settings.json is valid JSON"

# Check critical security settings
BYPASS_DISABLED=$(jq -r '(.permissions.disableBypassPermissionsMode // .disableBypassPermissionsMode // "not set")' "${MANAGED_PATH}")
MANAGED_PERMS_ONLY=$(jq -r '.allowManagedPermissionRulesOnly // "not set"' "${MANAGED_PATH}")
MANAGED_HOOKS_ONLY=$(jq -r '.allowManagedHooksOnly // "not set"' "${MANAGED_PATH}")
DEFAULT_MODE=$(jq -r '.permissions.defaultMode // "not set"' "${MANAGED_PATH}")

info "Security settings:"
info "  disableBypassPermissionsMode: ${BYPASS_DISABLED}"
info "  allowManagedPermissionRulesOnly: ${MANAGED_PERMS_ONLY}"
info "  allowManagedHooksOnly: ${MANAGED_HOOKS_ONLY}"
info "  permissions.defaultMode: ${DEFAULT_MODE}"

if [[ "${BYPASS_DISABLED}" == "disable" ]]; then
  pass "7.1 Bypass permissions mode is disabled"
else
  warn "7.1 disableBypassPermissionsMode is not set to 'disable'"
fi

if [[ "${MANAGED_PERMS_ONLY}" == "true" ]]; then
  pass "7.1 Only managed permission rules are enforced"
else
  warn "7.1 allowManagedPermissionRulesOnly is not enabled"
fi

# Check for deny rules
DENY_COUNT=$(jq '.permissions.deny // [] | length' "${MANAGED_PATH}" 2>/dev/null || echo 0)
info "  Deny rules configured: ${DENY_COUNT}"
if [[ "${DENY_COUNT}" -gt 0 ]]; then
  jq -r '.permissions.deny[]' "${MANAGED_PATH}" 2>/dev/null | while read -r rule; do
    info "    - ${rule}"
  done
  pass "7.1 Deny rules are configured (${DENY_COUNT} rules)"
else
  warn "7.1 No deny rules configured — consider adding restrictions"
fi
# HTH Guide Excerpt: end validate-managed-settings

summary
