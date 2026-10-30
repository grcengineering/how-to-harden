#!/usr/bin/env bash
# Shared helpers for the documented Desktop v2alpha models API.
# No requests occur while this file is sourced. Never enable shell tracing.
set +x
set -euo pipefail

desktop_require_key() {
  command -v curl >/dev/null || { echo 'UNKNOWN: curl is required' >&2; return 2; }
  command -v python3 >/dev/null || { echo 'UNKNOWN: python3 is required' >&2; return 2; }
  if [[ ! ${DEVIN_API_KEY:-} =~ ^cog_[A-Za-z0-9._-]+$ ]]; then
    echo 'UNKNOWN: inject a Devin cog_ service-user DEVIN_API_KEY; key is not printed' >&2
    return 2
  fi
}

desktop_request() {
  local method=$1 body=${2:-} etag=${3:-} status
  local -a args=(--disable --silent --show-error --connect-timeout 10 --max-time 30 --max-filesize 20971520
    --proto '=https' --tlsv1.2 --request "$method" --config -
    --dump-header "$HTH_TMP/headers" --output "$HTH_TMP/response.json"
    --write-out '%{http_code}' 'https://server.codeium.com/api/v2alpha/models')
  if [ "$method" = PUT ]; then
    args+=(--header 'Content-Type: application/json' --header "If-Match: $etag" --data-binary "@$body")
  fi
  # Auth travels over stdin, not the process argument list. Redirects are NOT followed.
  if ! status=$(printf 'header = "Authorization: Bearer %s"\n' "$DEVIN_API_KEY" | curl "${args[@]}"); then
    echo 'UNKNOWN: models API transport failure; no response body printed' >&2
    return 2
  fi
  if [ "$status" != 200 ]; then
    printf 'UNKNOWN: models API HTTP %s; do not infer policy enforcement\n' "$status" >&2
    [ "$status" != 412 ] || echo 'State changed: re-read and re-approve; no automatic retry' >&2
    return 2
  fi
}

desktop_report() {
  python3 - "$HTH_TMP/response.json" "$HTH_TMP/headers" <<'PY'
import hashlib, json, os, re, sys
from pathlib import Path
def unique(pairs):
    out = {}
    for k,v in pairs:
        if k in out: raise ValueError('duplicate key')
        out[k] = v
    return out
try:
    d = json.loads(Path(sys.argv[1]).read_text(), object_pairs_hook=unique)
    for key in ('allowed_model_uids', 'allowed_model_tags'):
        if not isinstance(d[key], list) or any(not isinstance(v,str) or not v for v in d[key]):
            raise ValueError()
    models = d['models']
    if not isinstance(models, list) or any(not isinstance(m,dict) or not isinstance(m.get('uid'),str)
        or type(m.get('allowed')) is not bool for m in models):
        raise ValueError()
    headers = Path(sys.argv[2]).read_text().splitlines()
    etags = [line.split(':',1)[1].strip() for line in headers if line.lower().startswith('etag:')]
    etag = etags[-1] if etags else None
    if not etag or not re.fullmatch(r'(?:W/)?"[\x21\x23-\x7e]+"',etag):
        raise ValueError()
    print(json.dumps({'credential_fingerprint':hashlib.sha256(os.environ['DEVIN_API_KEY'].encode()).hexdigest(),
                      'etag':etag, 'allowed_model_uids':d['allowed_model_uids'],
                      'allowed_model_tags':d['allowed_model_tags'],
                      'allowed_models':[m['uid'] for m in models if m['allowed']]}, indent=2))
except (ValueError, KeyError, TypeError, OSError):
    print('UNKNOWN: unexpected alpha API response; no raw body printed', file=sys.stderr)
    sys.exit(2)
PY
}
