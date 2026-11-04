#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tailscale-2.1
#   guide: https://howtoharden.com/guides/tailscale/#21-replace-broad-allows-with-least-privilege-grants
#   profile: L1
#   mode: read-only
#   requires: TAILSCALE_POLICY_INPUT(strict JSON admins/staff arrays), TAILSCALE_OUTPUT, bash, jq, python3
# HTH Tailscale 2.1 — Replace Broad Allows with Least-Privilege Grants; NIST AC-3, AC-4; SOC 2 CC6.1
# Sources: https://tailscale.com/docs/reference/syntax/grants
# https://tailscale.com/docs/reference/syntax/policy-file (available; 2026-11-04)
# Local generator only. This is a COMPLETE MINIMAL CANDIDATE, not a merge tool.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin build-grants-policy
hth_init 1
[[ -f "${TAILSCALE_POLICY_INPUT:-}" ]] || hth_unknown 'provide TAILSCALE_POLICY_INPUT with reviewed admins and staff'
python3 - "$TAILSCALE_POLICY_INPUT" "$HTH_TEMP/candidate.json" <<'PY'
import json
import pathlib
import re
import sys

def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError()
        result[key] = value
    return result

try:
    raw = pathlib.Path(sys.argv[1]).read_bytes()
    if len(raw) > 65536:
        raise ValueError()
    approved = json.loads(raw, object_pairs_hook=unique_object)
    if not isinstance(approved, dict) or set(approved) != {'admins', 'staff'}:
        raise ValueError()
    for names in approved.values():
        if not isinstance(names, list) or not 1 <= len(names) <= 100:
            raise ValueError()
        if not all(isinstance(x, str) and x == x.lower() and len(x) <= 254 and
                   re.fullmatch(r'[a-z0-9_.+\-]+@[a-z0-9.\-]+\.[a-z]{2,63}', x) for x in names):
            raise ValueError()
        if len(set(names)) != len(names):
            raise ValueError()
    if set(approved['admins']) & set(approved['staff']):
        raise ValueError()
except (OSError, ValueError, TypeError):
    sys.exit('UNKNOWN: require distinct, nonempty lowercase email arrays named admins and staff')

policy = {
    'groups': {'group:admins': approved['admins'], 'group:staff': approved['staff']},
    'tagOwners': {tag: ['group:admins'] for tag in ('tag:prod', 'tag:build', 'tag:ci')},
    # Explicitly empty legacy ACLs prevent an omitted-section allow-all fallback.
    'acls': [],
    'grants': [
        {'src':['group:admins'], 'dst':['tag:prod'], 'ip':['tcp:22', 'tcp:443']},
        {'src':['group:staff'], 'dst':['tag:prod'], 'ip':['tcp:443']},
        {'src':['tag:ci'], 'dst':['tag:build'], 'ip':['tcp:443']},
    ],
    'ssh': [],
    'tests': [
        {'src':approved['admins'][0], 'proto':'tcp', 'accept':['tag:prod:22', 'tag:prod:443'], 'deny':['tag:prod:5432']},
        {'src':approved['staff'][0], 'proto':'tcp', 'accept':['tag:prod:443'], 'deny':['tag:prod:22', 'tag:build:443']},
        {'src':'tag:ci', 'proto':'tcp', 'accept':['tag:build:443'], 'deny':['tag:prod:22', 'tag:prod:443']},
    ],
}
pathlib.Path(sys.argv[2]).write_text(json.dumps(policy, indent=2)+'\n')
PY
hth_save "$HTH_TEMP/candidate.json"
printf 'GENERATED-CANDIDATE: adapt the complete policy, retain required settings, and run server validation before deployment.\n'
# HTH Guide Excerpt: end build-grants-policy
