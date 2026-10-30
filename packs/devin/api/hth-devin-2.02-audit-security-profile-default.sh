#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-2.2
#   guide: https://howtoharden.com/guides/devin/#22-enforce-mandatory-session-security-profiles
#   profile: L2
#   mode: read-only
#   requires: DEVIN_API_KEY(enterprise Manage security profiles permission), HTH_PROFILE_LEVEL(2 or higher)
# HTH Devin 2.2: Enforce Mandatory Session Security Profiles
# Framework: NIST 800-53 AC-3, SC-7
# Sources: https://docs.devin.ai/product-guides/security-profiles
#          https://docs.devin.ai/v3-openapi.json (v3beta1 BETA, fetched 2026-10-29)
# Exit 0 = a mandatory read-only default with explicit network/MCP policies is configured; 1 = baseline gaps; 2 = unknown.
# GET endpoints require Manage security profiles (a write-capable permission); this pack makes no writes.
# No claim about already-running sessions, org/build defaults, Outpost network enforcement,
# human approvals, or suitability of each allowlisted destination. Review those separately.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin audit-security-profile-default
hth_init 2
hth_paginate '/v3beta1/enterprise/security-profiles' "$HTH_TEMP/profiles.jsonl"
hth_get '/v3beta1/enterprise/security-profile-settings' "$HTH_TEMP/settings.json"
jq -e '.default | (.selection == "none" or .selection == "profile")' \
  "$HTH_TEMP/settings.json" >/dev/null || hth_unknown 'malformed enterprise default selection'
if [[ "$(jq -r '.default.selection' "$HTH_TEMP/settings.json")" != profile ]]; then
  echo 'FINDING: no enterprise default security profile'; exit 1
fi
profile_id="$(jq -r '.default.profile_id // empty' "$HTH_TEMP/settings.json")"
[[ -n "$profile_id" ]] || hth_unknown 'profile selection has no profile_id'
jq -s --arg id "$profile_id" '[.[] | select(.profile_id == $id)]' \
  "$HTH_TEMP/profiles.jsonl" > "$HTH_TEMP/selected.json"
[[ "$(jq 'length' "$HTH_TEMP/selected.json")" == 1 ]] || hth_unknown 'default does not resolve to exactly one visible enterprise profile'
jq '.[0]' "$HTH_TEMP/selected.json" > "$HTH_TEMP/profile.json"
jq -e '(.enforcement_level == "mandatory" or .enforcement_level == "recommended") and
  (.git_access_level == "read_only" or .git_access_level == "read_write") and
  (.devin_mcp_read_only | type == "boolean") and (.remove_github_cli_token | type == "boolean") and
  (.net_policy == null or ((.net_policy | type == "object" and keys == ["allow"]) and
    (.net_policy.allow | type == "array") and
    all(.net_policy.allow[]; type == "object" and
      ((keys == ["hostname"] and (.hostname | type == "string" and length > 0)) or
       (keys == ["ipv4"] and (.ipv4 | type == "string" and length > 0)) or
       (keys == ["ipv6"] and (.ipv6 | type == "string" and length > 0)))))) and
  (.mcp_config == null or ((.mcp_config | type == "object" and keys == ["servers"]) and
    (.mcp_config.servers | type == "array") and all(.mcp_config.servers[]; type == "string" and length > 0)))' \
  "$HTH_TEMP/profile.json" >/dev/null || hth_unknown 'malformed security profile fields'
# Validate CIDR address families as well as JSON types; unknown schema never passes.
if python3 - "$HTH_TEMP/profile.json" <<'PYCODE'
import ipaddress, json, sys
with open(sys.argv[1]) as source:
    profile = json.load(source)
try:
    unrestricted = False
    for entry in (profile.get('net_policy') or {}).get('allow', []):
        for key, version in [('ipv4', 4), ('ipv6', 6)]:
            if key in entry:
                network = ipaddress.ip_network(entry[key], strict=False)
                if network.version != version:
                    raise ValueError('address-family mismatch')
                unrestricted = unrestricted or network.prefixlen == 0
except ValueError:
    print('UNKNOWN: invalid network-policy CIDR', file=sys.stderr)
    sys.exit(2)
if unrestricted:
    print('FINDING: network policy contains an unrestricted CIDR')
    sys.exit(1)
PYCODE
then
  :
else
  result=$?
  exit "$result"
fi
# This baseline is intentionally restrictive. An approved write workflow needs a separate review.
jq '[
  if .enforcement_level != "mandatory" then "default is only recommended" else empty end,
  if .net_policy == null then "network policy has no opinion" else empty end,
  if any((.net_policy.allow // [])[]; .hostname == "*" or .ipv4 == "0.0.0.0/0" or .ipv6 == "::/0")
    then "network policy contains an unrestricted destination" else empty end,
  if .mcp_config == null then "MCP policy has no opinion" else empty end,
  if .git_access_level != "read_only" then "git writes are permitted" else empty end,
  if .devin_mcp_read_only != true then "Devin management MCP writes are permitted" else empty end,
  if .remove_github_cli_token != true then "GitHub CLI token is retained" else empty end
]' "$HTH_TEMP/profile.json" > "$HTH_TEMP/findings.json"
if [[ "$(jq 'length' "$HTH_TEMP/findings.json")" != 0 ]]; then
  jq -r '.[] | "FINDING: " + .' "$HTH_TEMP/findings.json"; exit 1
fi
echo 'CONFIGURED: mandatory read-only enterprise default with explicit network/MCP policies; review allowlists and verify a newly booted session separately'
# HTH Guide Excerpt: end audit-security-profile-default
