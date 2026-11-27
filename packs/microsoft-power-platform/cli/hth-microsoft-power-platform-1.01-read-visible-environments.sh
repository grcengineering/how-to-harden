#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: microsoft-power-platform-1.1
#   guide: https://howtoharden.com/guides/microsoft-power-platform/#11-separate-and-inventory-production-environments
#   profile: L1
#   mode: read-only
#   requires: Power Platform CLI with reviewed existing auth profile, jq
# Source (reviewed 2026-11-27): https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/admin#pac-admin-list
# HTH Guide Excerpt: begin read-visible-environments
set +x
set -euo pipefail
fail() { printf 'UNKNOWN: %s\n' "$*" >&2; exit 2; }
[[ "${HTH_POWER_PLATFORM_KNOWN_ENV_ID:-}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || fail 'Missing or invalid HTH_POWER_PLATFORM_KNOWN_ENV_ID'

command -v pac >/dev/null || fail 'Power Platform CLI is not installed'
# Confirm the existing profile using pac auth who. No profile is changed here.
result=$(pac admin list --json) || fail 'Environment list failed'
jq -e --arg id "$HTH_POWER_PLATFORM_KNOWN_ENV_ID" '
  type=="array" and all(.[];type=="object") and
  any(.[]; any(.. | strings; ascii_downcase==($id|ascii_downcase)))
' <<<"$result" >/dev/null 2>&1 || fail 'Expected known environment is not visible or output is unsupported'
jq '{known_environment_visible:true,visible_environment_count:length,complete_tenant_coverage_checked:false}' <<<"$result"
# HTH Guide Excerpt: end read-visible-environments
