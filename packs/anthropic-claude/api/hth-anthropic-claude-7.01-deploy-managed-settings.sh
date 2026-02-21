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

# HTH Guide Excerpt: begin managed-settings-baseline
# Anthropic official example: settings-lax.json (L1 Baseline)
# Source: github.com/anthropics/claude-code/blob/main/examples/settings/settings-lax.json
# Prevents --dangerously-skip-permissions and blocks plugin marketplaces.
# Deploy to:
#   macOS:   /Library/Application Support/ClaudeCode/managed-settings.json
#   Linux:   /etc/claude-code/managed-settings.json
#   Windows: C:\Program Files\ClaudeCode\managed-settings.json
cat << 'BASELINE'
{
  "permissions": {
    "disableBypassPermissionsMode": "disable"
  },
  "strictKnownMarketplaces": []
}
BASELINE
# HTH Guide Excerpt: end managed-settings-baseline

# HTH Guide Excerpt: begin managed-settings-hardened
# Anthropic official example: settings-strict.json (L2 Hardened)
# Source: github.com/anthropics/claude-code/blob/main/examples/settings/settings-strict.json
# Blocks bypass, enforces managed-only permissions and hooks,
# denies web access, requires Bash approval, locks sandbox settings.
cat << 'HARDENED'
{
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "ask": [
      "Bash"
    ],
    "deny": [
      "WebSearch",
      "WebFetch"
    ]
  },
  "allowManagedPermissionRulesOnly": true,
  "allowManagedHooksOnly": true,
  "strictKnownMarketplaces": [],
  "sandbox": {
    "autoAllowBashIfSandboxed": false,
    "excludedCommands": [],
    "network": {
      "allowUnixSockets": [],
      "allowAllUnixSockets": false,
      "allowLocalBinding": false,
      "allowedDomains": [],
      "httpProxyPort": null,
      "socksProxyPort": null
    },
    "enableWeakerNestedSandbox": false
  }
}
HARDENED
# HTH Guide Excerpt: end managed-settings-hardened

# HTH Guide Excerpt: begin managed-settings-sandbox
# Anthropic official example: settings-bash-sandbox.json (L3 Sandbox)
# Source: github.com/anthropics/claude-code/blob/main/examples/settings/settings-bash-sandbox.json
# Enables OS-level bash sandboxing with no escape hatch.
# Platform support: macOS (Seatbelt), Linux/WSL2 (bubblewrap).
cat << 'SANDBOX'
{
  "allowManagedPermissionRulesOnly": true,
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": false,
    "allowUnsandboxedCommands": false,
    "excludedCommands": [],
    "network": {
      "allowUnixSockets": [],
      "allowAllUnixSockets": false,
      "allowLocalBinding": false,
      "allowedDomains": [],
      "httpProxyPort": null,
      "socksProxyPort": null
    },
    "enableWeakerNestedSandbox": false
  }
}
SANDBOX
# HTH Guide Excerpt: end managed-settings-sandbox

# HTH Guide Excerpt: begin managed-settings-comprehensive
# Comprehensive managed-settings.json — combines all security controls.
# Reference: code.claude.com/docs/en/settings
# Extends the official examples with practical deny rules, model
# restrictions, org login enforcement, and MCP server controls.
cat << 'COMPREHENSIVE'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "deny": [
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(rm -rf *)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./credentials/**)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "WebSearch",
      "WebFetch"
    ],
    "ask": [
      "Bash"
    ],
    "allow": [
      "Bash(npm run *)",
      "Bash(npm test)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)"
    ]
  },
  "allowManagedPermissionRulesOnly": true,
  "allowManagedHooksOnly": true,
  "strictKnownMarketplaces": [],
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "model": "claude-sonnet-4-6",
  "availableModels": ["sonnet", "haiku"],
  "forceLoginMethod": "claudeai",
  "forceLoginOrgUUID": "REPLACE-WITH-YOUR-ORG-UUID",
  "cleanupPeriodDays": 7,
  "allowedMcpServers": [
    {"serverName": "github"},
    {"serverName": "memory"}
  ],
  "deniedMcpServers": [
    {"serverName": "filesystem"},
    {"serverName": "shell"},
    {"serverName": "puppeteer"}
  ],
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": false,
    "allowUnsandboxedCommands": false,
    "excludedCommands": ["docker"],
    "network": {
      "allowUnixSockets": [],
      "allowAllUnixSockets": false,
      "allowLocalBinding": false,
      "allowedDomains": [
        "github.com",
        "*.npmjs.org",
        "registry.yarnpkg.com"
      ],
      "httpProxyPort": null,
      "socksProxyPort": null
    },
    "enableWeakerNestedSandbox": false
  }
}
COMPREHENSIVE
# HTH Guide Excerpt: end managed-settings-comprehensive

summary
