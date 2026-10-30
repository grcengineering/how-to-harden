#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-desktop-4.4
#   guide: https://howtoharden.com/guides/devin-desktop/#44-allow-only-approved-models
#   profile: L2
#   mode: mutating
#   requires: python3; curl for --apply; DEVIN_API_KEY (cog_ service user with Use Devin Desktop and account.windsurf.admin) for --apply
# HTH Devin Desktop 4.4: Allow Only Approved Models
# Profile Level: L2 (Walk) | NIST 800-53: AC-3
# Source: https://docs.devin.ai/desktop/accounts/api-reference/update-models
# Status: alpha (v2alpha); verified 2026-10-29, no live API validation.
set +x
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin model-allowlist
# Default plan mode performs NO request. Full-replacement PUT requires --apply.
# Usage: bash this-file.sh approved.json snapshot.json [--apply]
# approved.json contains exactly allowed_model_uids and allowed_model_tags arrays.
# snapshot.json is the read-only pack's report, including the reviewed state's ETag.
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ] || { [ "$#" -eq 3 ] && [ "$3" != --apply ]; }; then
  echo 'usage: approved.json snapshot.json [--apply]' >&2; exit 2
fi
umask 077
HTH_TMP=$(mktemp -d)
trap 'rm -rf "$HTH_TMP"' EXIT
python3 - "$1" "$2" "$HTH_TMP" <<'PY'
import json, re, sys
from pathlib import Path
def unique(pairs):
    out = {}
    for k,v in pairs:
        if k in out: raise ValueError('duplicate key')
        out[k] = v
    return out
try:
    desired = json.loads(Path(sys.argv[1]).read_text(), object_pairs_hook=unique)
    snapshot = json.loads(Path(sys.argv[2]).read_text(), object_pairs_hook=unique)
    keys = {'allowed_model_uids','allowed_model_tags'}
    if not isinstance(desired,dict) or set(desired) != keys:
        raise ValueError()
    for k in keys:
        if not isinstance(desired[k],list) or any(not isinstance(v,str) or not v or any(ord(c)<32 for c in v)
                                                for v in desired[k]):
            raise ValueError()
    if not any(desired[k] for k in keys):
        raise ValueError()  # Avoid an ambiguous/locking empty selection in this pack.
    fingerprint = snapshot['credential_fingerprint']
    if not isinstance(fingerprint,str) or not re.fullmatch(r'[a-f0-9]{64}',fingerprint):
        raise ValueError()
    etag = snapshot['etag']
    if not isinstance(etag,str) or not re.fullmatch(r'(?:W/)?"[\x21\x23-\x7e]+"',etag):
        raise ValueError()
    Path(sys.argv[3], 'desired.json').write_text(json.dumps(desired))
    Path(sys.argv[3], 'etag').write_text(etag)
    Path(sys.argv[3], 'fingerprint').write_text(fingerprint)
    print(json.dumps({'operation':'replace model allowlist', 'desired':desired},indent=2))
except (ValueError, KeyError, TypeError, OSError):
    print('UNKNOWN: invalid desired state/snapshot; nothing sent', file=sys.stderr)
    sys.exit(2)
PY
if [ "${3:-}" != --apply ]; then
  echo 'PLAN ONLY: no request sent. Review scope, desired models, and snapshot before --apply.'
  exit 0
fi
desktop_require_key
python3 - "$HTH_TMP/fingerprint" <<'PY'
import hashlib, os, sys
from pathlib import Path
if hashlib.sha256(os.environ['DEVIN_API_KEY'].encode()).hexdigest() != Path(sys.argv[1]).read_text():
    print('UNKNOWN: snapshot was made with a different credential; nothing sent', file=sys.stderr)
    sys.exit(2)
PY
ETAG=$(cat "$HTH_TMP/etag")
desktop_request PUT "$HTH_TMP/desired.json" "$ETAG"
desktop_report > "$HTH_TMP/report.json"
python3 - "$HTH_TMP/desired.json" "$HTH_TMP/report.json" <<'PY'
import json, sys
from pathlib import Path
expected, observed = (json.loads(Path(p).read_text()) for p in sys.argv[1:])
if any(set(expected[k]) != set(observed[k]) for k in ('allowed_model_uids','allowed_model_tags')):
    print('UNKNOWN: update response did not match desired lists; investigate before retrying', file=sys.stderr)
    sys.exit(2)
print('PASS: API returned the requested stored allowlist. Verify a normal member model picker separately.')
PY
# HTH Guide Excerpt: end model-allowlist
