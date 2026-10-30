#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-2.1
#   guide: https://howtoharden.com/guides/devin/#21-restrict-inbound-access-with-ip-access-lists
#   profile: L2
#   mode: read-only
#   requires: DEVIN_API_KEY(enterprise credential with ManageIPWhitelist), DEVIN_EXPECTED_IP_RANGES(path to approved JSON array of CIDRs), HTH_PROFILE_LEVEL(2 or higher)
# HTH Devin 2.1: Restrict Inbound Access with IP Access Lists
# Framework: NIST 800-53 SC-7
# Sources: https://docs.devin.ai/enterprise/security-access/ip-access-lists
#          https://docs.devin.ai/v3-openapi.json (v3 available, fetched 2026-10-29)
# GET itself requires ManageIPWhitelist (a write-capable permission). This script never writes.
# Exit 0 = exact canonical CIDR set matches approved baseline; 1 = drift/unrestricted; 2 = unknown.
# This does NOT prove live rejection from an unapproved network; test that separately.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin verify-ip-access-list
hth_init 2
[[ -r "${DEVIN_EXPECTED_IP_RANGES:-}" ]] || hth_unknown 'set DEVIN_EXPECTED_IP_RANGES to a readable approved JSON array'
hth_get '/v3/enterprise/ip-access-list' "$HTH_TEMP/ip-access-list.json"
# ipaddress canonicalizes IPv4/IPv6 networks; no addresses are printed.
# Conditional execution preserves finding (1) versus unknown (2) exit codes.
if python3 - "$HTH_TEMP/ip-access-list.json" "$DEVIN_EXPECTED_IP_RANGES" <<'PY'
import ipaddress, json, sys
try:
    with open(sys.argv[1]) as source:
        actual = json.load(source)['ip_ranges']
    with open(sys.argv[2]) as source:
        expected = json.load(source)
    def networks(values):
        if not isinstance(values, list) or any(not isinstance(v, str) for v in values):
            raise ValueError('not an array of strings')
        return {ipaddress.ip_network(v, strict=False) for v in values}
    current, approved = networks(actual), networks(expected)
    if not approved or any(n.prefixlen == 0 for n in approved):
        raise ValueError('approved baseline must restrict access')
except (OSError, ValueError, KeyError, TypeError):
    print('UNKNOWN: malformed response or missing/unsafe approved CIDR baseline', file=sys.stderr)
    sys.exit(2)
if not current or any(n.prefixlen == 0 for n in current):
    print('FINDING: no effective IP restriction for at least one address family')
    sys.exit(1)
if current != approved:
    print(f'FINDING: CIDR drift ({len(current - approved)} unexpected, {len(approved - current)} missing)')
    sys.exit(1)
print(f'MATCH: {len(current)} canonical CIDRs match the approved baseline; live access denial not tested')
PY
then
  exit 0
else
  result=$?
  exit "$result"
fi
# HTH Guide Excerpt: end verify-ip-access-list
