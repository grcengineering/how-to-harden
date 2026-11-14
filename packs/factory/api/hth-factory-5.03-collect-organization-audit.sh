#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-5.3
#   guide: https://howtoharden.com/guides/factory/#53-collect-organization-audit-metadata-with-explicit-scope
#   profile: L2
#   mode: read-only
#   requires: FACTORY_API_KEY(Enterprise human Owner), FACTORY_AUDIT_START, FACTORY_AUDIT_END, FACTORY_AUDIT_OUTPUT(new private file), bash, curl, jq, python3
# Source: https://docs.factory.com/api-reference/organization (available; verified 2026-11-14)
# Active organization only. No regional aggregation, streaming or event-payload export.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin collect-organization-audit
hth_api_init 2
[[ -n "${FACTORY_AUDIT_OUTPUT:-}" ]] || hth_unknown 'set FACTORY_AUDIT_OUTPUT to a new private file'
python3 - <<'PY' || hth_unknown 'set an ordered UTC audit window as YYYY-MM-DDTHH:MM:SSZ'
from datetime import datetime
import os
import re
import sys
try:
    values = [os.environ[name] for name in ('FACTORY_AUDIT_START', 'FACTORY_AUDIT_END')]
    if not all(re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', value) for value in values):
        raise ValueError()
    start, end = [datetime.strptime(value, '%Y-%m-%dT%H:%M:%SZ') for value in values]
    if start >= end:
        raise ValueError()
except (KeyError, ValueError):
    sys.exit(2)
PY
query="$(jq -rn --arg start "$FACTORY_AUDIT_START" --arg end "$FACTORY_AUDIT_END" \
  '"limit=100&startDate=" + ($start | @uri) + "&endDate=" + ($end | @uri)')"
cursor='' pages=0
: > "$HTH_TEMP/events.jsonl"
: > "$HTH_TEMP/cursors.jsonl"
while :; do
  path="/api/v0/organization/audit?${query}"
  [[ -z "$cursor" ]] || path+="&cursor=$(jq -rn --arg cursor "$cursor" '$cursor | @uri')"
  # On an authority change/cursor restart error, discard this run and rerun the
  # complete unchanged time window. Never accept only the first pages as complete.
  hth_get "$path" "$HTH_TEMP/page.json"
  jq -e '(.events | type == "array") and has("nextCursor") and
    (.nextCursor == null or (.nextCursor | type == "string" and length > 0)) and
    ((has("unavailableOrganizations") | not) or .unavailableOrganizations == []) and
    all(.events[];
      (.id | type == "string" and length > 0) and
      (.eventType | type == "string" and length > 0) and
      (.source | type == "string") and
      (.createdAt | type == "string" and length > 0) and
      ((has("organizationId") | not) or (.organizationId | type == "string" and length > 0)))' \
    "$HTH_TEMP/page.json" >/dev/null 2>&1 || hth_unknown 'malformed or regionally incomplete audit response'
  # Payload, target, actor email and unknown fields stay out of the saved artifact.
  jq -c '.events[] | {id, organizationId, eventType, source, createdAt}' \
    "$HTH_TEMP/page.json" >> "$HTH_TEMP/events.jsonl"
  pages=$((pages + 1))
  cursor="$(jq -r '.nextCursor // empty' "$HTH_TEMP/page.json")"
  [[ -n "$cursor" ]] || break
  (( $(jq '.events | length' "$HTH_TEMP/page.json") > 0 )) || hth_unknown 'empty nonterminal audit page'
  if jq -se --arg cursor "$cursor" 'index($cursor) != null' "$HTH_TEMP/cursors.jsonl" >/dev/null; then
    hth_unknown 'repeated audit cursor; incomplete evidence discarded'
  fi
  (( pages < HTH_MAX_PAGES )) || hth_unknown 'audit page limit reached; narrow the time window'
  jq -nc --arg cursor "$cursor" '$cursor' >> "$HTH_TEMP/cursors.jsonl"
done
python3 - "$HTH_TEMP/events.jsonl" <<'PY' || hth_unknown 'invalid audit event timestamp; incomplete evidence discarded'
from datetime import datetime
import json
import re
import sys
try:
    with open(sys.argv[1], encoding='utf-8') as records:
        for line in records:
            stamp = json.loads(line)['createdAt']
            if not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})', stamp):
                raise ValueError()
            datetime.fromisoformat(stamp.replace('Z', '+00:00'))
except (ValueError, KeyError, TypeError):
    sys.exit(2)
PY
jq -s --arg start "$FACTORY_AUDIT_START" --arg end "$FACTORY_AUDIT_END" \
  '{scope: "active-organization", startDate: $start, endDate: $end,
    events: (unique_by([.organizationId, .id]))}' \
  "$HTH_TEMP/events.jsonl" > "$HTH_TEMP/inventory.json"
hth_save_private "$HTH_TEMP/inventory.json" "$FACTORY_AUDIT_OUTPUT"
printf 'COLLECTED: %s audit metadata records for the active organization; inspect details and approvals in the audit console.\n' \
  "$(jq '.events | length' "$HTH_TEMP/inventory.json")"
# HTH Guide Excerpt: end collect-organization-audit
