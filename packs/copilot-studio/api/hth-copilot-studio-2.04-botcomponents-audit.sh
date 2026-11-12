#!/usr/bin/env bash
set -euo pipefail
# 2.04: Component drift inventory; Profile L2 (Walk); NIST AC-6/CM-3/AU-6.
# Guide: https://howtoharden.com/guides/copilot-studio/
# Read-only. Requires curl, jq, python3 and a scoped Dataverse bearer token.
# API reference (available): https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/botcomponent
# Paging: https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/query/page-results
# Never enable shell tracing when using bearer tokens.
# HTH Guide Excerpt: begin audit
: "${DATAVERSE_URL:?Set the HTTPS Dataverse organization origin}"
: "${DATAVERSE_TOKEN:?Supply a short-lived token for that organization}"
export DATAVERSE_URL DATAVERSE_TOKEN
python3 - <<'CHECK'
import os, urllib.parse
if any(ord(c)<32 or ord(c)==127 for c in os.environ['DATAVERSE_URL']+os.environ['DATAVERSE_TOKEN']):
    raise SystemExit('Control characters are not allowed in URL or token')
u=urllib.parse.urlsplit(os.environ['DATAVERSE_URL'])
if u.scheme!='https' or not u.hostname or u.username or u.password or u.query or u.fragment or u.path not in ('','/'):
    raise SystemExit('DATAVERSE_URL must be an HTTPS origin, without credentials or a path')
CHECK
origin="${DATAVERSE_URL%/}"
# Do not place tokens in command arguments or follow redirects.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
chmod 700 "$work"
umask 077
printf 'Authorization: Bearer %s\n' "$DATAVERSE_TOKEN" > "$work/headers"
url="$origin/api/data/v9.2/botcomponents?\$select=botcomponentid,name,schemaname,componenttype,data,content,modifiedon"
: > "$work/rows"
: > "$work/seen"
while [[ -n "$url" ]]; do
  # A foreign-origin nextLink must never receive the bearer token.
  PAGE_URL="$url" python3 - <<'CHECK'
import os, urllib.parse
if any(ord(c)<32 or ord(c)==127 for c in os.environ['PAGE_URL']):
    raise SystemExit('Control characters are not allowed in pagination')
b=urllib.parse.urlsplit(os.environ['DATAVERSE_URL'])
u=urllib.parse.urlsplit(os.environ['PAGE_URL'])
if (u.scheme,u.netloc)!=(b.scheme,b.netloc) or u.username or u.password or not u.path.startswith('/api/data/v9.2/') or u.fragment:
    raise SystemExit('Rejected unsafe pagination URL')
CHECK
  if grep -Fqx -- "$url" "$work/seen"; then echo 'Repeated pagination URL' >&2; exit 1; fi
  printf '%s\n' "$url" >> "$work/seen"
  status=$(curl -q --silent --show-error --fail --max-time 60 --connect-timeout 15 --max-redirs 0 --max-filesize 52428800 --proto '=https' \
    --header @"$work/headers" --header 'Accept: application/json' \
    --header 'OData-Version: 4.0' --header 'OData-MaxVersion: 4.0' \
    --header 'Prefer: odata.maxpagesize=500' --output "$work/page" --write-out '%{http_code}' "$url")
  [[ "$status" == 200 ]] || { echo "Unexpected HTTP status: $status" >&2; exit 1; }
  jq -e '(.value | type == "array") and ((has("error")) | not) and all(.value[]; type == "object" and (.botcomponentid | type == "string" and length > 0))' "$work/page" >/dev/null
  python3 - "$work/page" >> "$work/rows" <<'HASH'
import json,sys,hashlib
for row in json.load(open(sys.argv[1]))['value']:
    data=row.get('data')
    content=row.get('content')
    row={k:row.get(k) for k in ('botcomponentid','name','schemaname','componenttype','modifiedon')}
    row['data_sha256']=hashlib.sha256(data.encode()).hexdigest() if isinstance(data,str) else None
    row['content_sha256']=hashlib.sha256(content.encode()).hexdigest() if isinstance(content,str) else None
    print(json.dumps(row,sort_keys=True))
HASH
  url=$(jq -er 'if .["@odata.nextLink"] == null then "" elif (.["@odata.nextLink"] | type) == "string" then .["@odata.nextLink"] else error("Invalid nextLink") end' "$work/page")
done
jq -e -s 'map(.botcomponentid) | length == (unique | length)' "$work/rows" >/dev/null
jq -s 'sort_by(.botcomponentid)' "$work/rows"
# HTH Guide Excerpt: end audit
