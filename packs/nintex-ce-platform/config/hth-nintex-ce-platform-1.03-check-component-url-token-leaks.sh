#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: nintex-ce-platform-1.3
#   guide: https://howtoharden.com/guides/nintex-ce-platform/#13-protect-component-workflow-start-tokens
#   profile: L2
#   mode: read-only
#   requires: Bash, Python 3 standard library, approved local Nintex endpoint or OAS artifact, NINTEX_COMPONENT_ARTIFACT
# Vendor contract: https://help.nintex.com/en-us/nwc/content/designer/Startevents/ComponentWorkflow.htm
# HTH Guide Excerpt: begin check-component-url-token-leaks
set +x
set -euo pipefail

: "${NINTEX_COMPONENT_ARTIFACT:?Set the local endpoint/OAS file intended for sharing}"
# This works offline and never reports the matching URLs or query values.
python3 -I - <<'PYTHON'
import html
import json
import os
from pathlib import Path
import re
from urllib.parse import unquote

path = Path(os.environ["NINTEX_COMPONENT_ARTIFACT"])
if not path.is_file() or path.stat().st_size > 8 * 1024 * 1024:
    raise SystemExit("Expected a local artifact of at most 8 MiB.")
try:
    raw = path.read_text(encoding="utf-8-sig")
except (OSError, UnicodeError):
    raise SystemExit("Cannot read artifact as UTF-8.") from None
if not raw.strip():
    raise SystemExit("Artifact is empty.")

def strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key, child in value.items():
            yield key
            yield from strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from strings(child)

try:
    decoded = list(strings(json.loads(raw)))
except (ValueError, RecursionError):
    decoded = []
# Inspect raw plus decoded JSON strings to detect encoded query pairs.
placeholder = {"", "{token}", "<token>", "[redacted]", "redacted"}
query = re.compile(r"[?&]token=([^&\s\x22\x27]*)", re.IGNORECASE)
potential = 0
for line in [raw, *decoded]:
    canonical = html.unescape(line)
    for _ in range(2):
        canonical = unquote(canonical)
    if any(match.casefold() not in placeholder for match in query.findall(canonical)):
        potential += 1
print(json.dumps({"scope": "offline-query-token-check", "needsReview": bool(potential)}))
raise SystemExit(1 if potential else 0)
PYTHON
# HTH Guide Excerpt: end check-component-url-token-leaks
