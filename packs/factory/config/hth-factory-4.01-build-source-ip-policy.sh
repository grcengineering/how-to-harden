#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-4.1
#   guide: https://howtoharden.com/guides/factory/#41-restrict-the-source-ips-of-authenticated-factory-access
#   profile: L3
#   mode: read-only
#   requires: FACTORY_ALLOWED_IPS_FILE(reviewed JSON array of corporate IPv4 addresses or CIDRs), bash, jq, python3
# HTH Factory 4.1 — NIST AC-17, SC-7
# Source: https://docs.factory.com/enterprise/llm-safety-and-agent-controls (available; verified 2026-10-30)
# Emits an org-settings fragment to stdout; never installs it or contacts Factory.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin build-source-ip-policy
hth_init 3
[[ -n "${FACTORY_ALLOWED_IPS_FILE:-}" ]] || hth_unknown 'provide FACTORY_ALLOWED_IPS_FILE; no default source IP is safe'
python3 - "$FACTORY_ALLOWED_IPS_FILE" <<'PY'
import ipaddress
import json
import sys
try:
    with open(sys.argv[1], encoding='utf-8') as source:
        entries = json.load(source)
    if not isinstance(entries, list) or not entries or any(not isinstance(x, str) for x in entries):
        raise ValueError()
    networks = [ipaddress.ip_network(x, strict=False) for x in entries]
    if any(n.version != 4 or n.prefixlen == 0 or n.is_loopback or n.is_multicast or n.is_unspecified for n in networks):
        raise ValueError()
except (OSError, ValueError, TypeError):
    print('UNKNOWN: provide a nonempty IPv4 list; IPv6 and unrestricted /0 are refused', file=sys.stderr)
    sys.exit(2)
print(json.dumps({'networkPolicy': {'allowedIps': sorted({str(n) for n in networks})}}, indent=2))
PY
# HTH Guide Excerpt: end build-source-ip-policy
