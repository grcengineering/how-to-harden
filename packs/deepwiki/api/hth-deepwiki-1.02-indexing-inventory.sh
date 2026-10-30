#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: deepwiki-1.2
#   guide: https://howtoharden.com/guides/deepwiki/#12-review-indexed-repositories-and-additional-branches
#   profile: L2
#   mode: read-only
#   requires: curl, python3, DEVIN_API_KEY(scoped service user), DEVIN_ORG_ID
# HTH DeepWiki 1.2: Read the complete indexed-repository and branch inventory
# Profile Level: L2 (Walk) | NIST 800-53: AC-6, CM-8
# Sources (available; fetched 2026-10-29):
#   https://docs.devin.ai/v3-openapi.json
#   https://docs.devin.ai/api-reference/authentication
# GET /v3/organizations/{org_id}/repositories/indexing, cursor-paginated.
# Reads only; outputs approved schema fields, never the credential or raw error.
# Inventory may reveal private repo names. Protect output and do not publish it.
# No redirect following, no custom host, no inherited curlrc, no live test run.
# Exit 0: complete inventory (NOT compliance); 2: unknown/incomplete/precondition.

# HTH Guide Excerpt: begin read-indexed-repository-inventory
set +x
set -euo pipefail
umask 077
if [[ $# -ne 0 ]]; then
  echo "Usage: inject DEVIN_API_KEY and DEVIN_ORG_ID, then run this script with no arguments" >&2
  exit 2
fi
for tool in curl python3; do
  command -v "$tool" >/dev/null 2>&1 || { echo "PRECONDITION: $tool required" >&2; exit 2; }
done
if [[ ! "${DEVIN_API_KEY:-}" =~ ^cog_[A-Za-z0-9._-]+$ || ! "${DEVIN_ORG_ID:-}" =~ ^org-[A-Za-z0-9_-]+$ ]]; then
  echo "PRECONDITION: inject a current cog_ credential and an org- organization ID" >&2
  exit 2
fi
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
printf '%s' '{"items":[],"cursors":[]}' > "$work/state.json"
cursor=""
for ((page = 1; page <= 1000; page++)); do
  query=(--data-urlencode "first=200")
  [[ -z "$cursor" ]] || query+=(--data-urlencode "after=$cursor")
  # Authorization travels over stdin, not argv. Only a GET is issued.
  if ! status=$(curl --disable --silent --show-error --fail \
      --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 60 \
      --max-filesize 20971520 \
      --config - --get "https://api.devin.ai/v3/organizations/$DEVIN_ORG_ID/repositories/indexing" \
      "${query[@]}" --output "$work/page.json" --write-out '%{http_code}' <<EOF
header = "Authorization: Bearer $DEVIN_API_KEY"
header = "Accept: application/json"
EOF
  ); then
    echo "UNKNOWN: inventory request failed (HTTP ${status:-unavailable}); no complete inventory produced" >&2
    exit 2
  fi
  if [[ "$status" != "200" ]]; then
    echo "UNKNOWN: unexpected HTTP status; no complete inventory produced" >&2
    exit 2
  fi
  if ! python3 - "$work" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
try:
    if (root / "page.json").stat().st_size > 20 * 1024 * 1024:
        raise ValueError("oversized response")
    page = json.loads((root / "page.json").read_text(encoding="utf-8"))
    state = json.loads((root / "state.json").read_text(encoding="utf-8"))
    if not isinstance(page, dict) or not isinstance(page.get("items"), list):
        raise ValueError("invalid page")
    # HTH fail-closed policy requires explicit pagination even though OpenAPI
    # supplies a default false flag. An omitted field is not completeness proof.
    next_page = page["has_next_page"]
    cursor = page["end_cursor"]
    if type(next_page) is not bool or (cursor is not None and not isinstance(cursor, str)):
        raise ValueError("invalid pagination")
    if next_page and (not cursor or cursor in state["cursors"] or any(ord(c) < 32 for c in cursor)):
        raise ValueError("invalid or repeated cursor")
    known = {item["repository_path"] for item in state["items"]}
    for item in page["items"]:
        if not isinstance(item, dict):
            raise ValueError("invalid item")
        path, enabled, branches = item.get("repository_path"), item.get("indexing_enabled"), item.get("branches")
        if not isinstance(path, str) or not path or path in known or type(enabled) is not bool:
            raise ValueError("invalid repository")
        if not isinstance(branches, list) or not all(isinstance(branch, str) for branch in branches):
            raise ValueError("invalid branches")
        known.add(path)
        state["items"].append({"repository_path": path, "indexing_enabled": enabled, "branches": branches})
    if next_page:
        state["cursors"].append(cursor)
    (root / "state.json").write_text(json.dumps(state), encoding="utf-8")
    (root / "cursor").write_text(cursor if next_page else "", encoding="utf-8")
except (OSError, UnicodeError, ValueError, TypeError, KeyError, RecursionError):
    print("UNKNOWN: invalid or inconsistent API response; no complete inventory produced", file=sys.stderr)
    sys.exit(2)
PY
  then
    exit 2
  fi
  cursor=$(cat "$work/cursor")
  if [[ -z "$cursor" ]]; then
    python3 - "$work/state.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as source:
    items = json.load(source)["items"]
print(json.dumps({"complete": True, "repository_count": len(items), "repositories": sorted(items, key=lambda row: row["repository_path"])}, indent=2))
PY
    echo "Inventory complete; compare repositories and branches with your approved scope. No compliance verdict." >&2
    exit 0
  fi
done
echo "UNKNOWN: exceeded 1000 pages; no complete inventory produced" >&2
exit 2
# HTH Guide Excerpt: end read-indexed-repository-inventory
