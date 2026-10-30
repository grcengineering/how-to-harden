#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-desktop-2.1
#   guide: https://howtoharden.com/guides/devin-desktop/#21-allow-only-approved-extensions
#   profile: L2
#   mode: read-only
#   requires: python3
# HTH Devin Desktop 2.1: Allow Only Approved Extensions
# Profile Level: L2 | NIST 800-53: CM-6
# Verified against official documentation: 2026-10-29; no live product validation.

# HTH Guide Excerpt: begin extension-allowlist
set -euo pipefail
# Source: https://docs.devin.ai/desktop/controls
# Emits a Linux policy.json fragment; merge into the existing policy before deployment.
# Usage: bash this-file.sh ms-python.python github.vscode-pull-request-github
# Each argument is an explicitly approved extension ID, not an entire publisher.
python3 - "$@" <<'PYCODE'
import json, re, sys
ids = sys.argv[1:]
if not ids or any(not re.fullmatch(r"[A-Za-z0-9_-]+\.[A-Za-z0-9_.-]+", x) for x in ids):
    sys.exit("usage: provide one or more approved publisher.extension identifiers")
allow = {"*": False, **dict.fromkeys(ids, True)}
# AllowedExtensions is a JSON STRING, not a nested object.
print(json.dumps({"AllowedExtensions": json.dumps(allow, sort_keys=True)}, indent=2))
PYCODE
# HTH Guide Excerpt: end extension-allowlist
