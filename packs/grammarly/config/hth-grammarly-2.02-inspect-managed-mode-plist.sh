#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: grammarly-2.2
#   guide:   https://howtoharden.com/guides/grammarly/
#   profile: L2
#   mode:    read-only
#   requires: GRAMMARLY_MANAGED_PLIST (macOS native desktop preferences), Python 3
# First-party source: https://support.grammarly.com/hc/en-us/articles/8341171286541-Configure-Managed-Mode
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
file=${GRAMMARLY_MANAGED_PLIST:?Set an authorized local plist file path}
[[ -f "$file" && ! -L "$file" ]] || exit 2
python3 - "$file" <<'PYTHON'
import json
import plistlib
import sys

with open(sys.argv[1], "rb") as source:
    raw = source.read(1048577)
if len(raw) > 1048576:
    sys.exit("plist exceeds the local 1 MiB limit")
try:
    payload = plistlib.loads(raw)
except Exception:
    sys.exit("could not parse plist")
if not isinstance(payload, dict):
    sys.exit("expected a native plist dictionary")
from uuid import UUID
token = payload.get("GrammarlyEnrollmentToken")
try:
    parsed = UUID(token) if isinstance(token, str) else None
except ValueError:
    parsed = None
if parsed is None or str(parsed) != token.lower() or parsed.int == 0:
    sys.exit("Grammarly enrollment token is absent or not a nonzero canonical UUID")
print(json.dumps({"scope": "input-plist-only", "enrollment_token_shape_valid": True}))
PYTHON
# HTH Guide Excerpt: end read-evidence
