#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: textexpander-2.1
#   guide:   https://howtoharden.com/guides/textexpander/
#   profile: L2
#   mode:    read-only
#   requires: TEXTEXPANDER_UPDATE_PLIST, TEXTEXPANDER_UPDATE_ROUTE (vendor or mdm), Python 3
# First-party source: https://textexpander.com/learn/best-practices-for-deploying-textexpander-via-mdm
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
file=${TEXTEXPANDER_UPDATE_PLIST:?Set an authorized local plist file path}
[[ -f "$file" && ! -L "$file" ]] || exit 2
route=${TEXTEXPANDER_UPDATE_ROUTE:?Set vendor or mdm as the approved update route}
[[ "$route" =~ ^(vendor|mdm)$ ]] || exit 2
python3 - "$file" "$route" <<'PYTHON'
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
keys = ("SUEnableAutomaticChecks", "SUEnableAutomaticDownload")
if any(type(payload.get(key)) is not bool for key in keys):
    sys.exit("update preferences are missing or not explicit booleans")
auto = sys.argv[2] == "vendor"
checks, download = (payload[key] for key in keys)
matches = checks == download == auto
print(json.dumps({"scope": "input-plist-only", "automatic_checks": checks,
                  "automatic_download": download, "matches": matches}))
sys.exit(0 if matches else 1)
PYTHON
# HTH Guide Excerpt: end read-evidence
