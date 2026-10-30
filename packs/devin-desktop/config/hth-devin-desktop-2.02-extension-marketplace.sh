#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: devin-desktop-2.2
#   guide: https://howtoharden.com/guides/devin-desktop/#22-pin-the-extension-marketplace
#   profile: L2
#   mode: read-only
#   requires: python3
# HTH Devin Desktop 2.2: Pin the Extension Marketplace
# Profile Level: L2 | NIST 800-53: CM-6
# Verified against official documentation: 2026-10-29; no live product validation.

# HTH Guide Excerpt: begin extension-marketplace
set -euo pipefail
# Source: https://docs.devin.ai/desktop/controls
# Emit only: this does not contact the URL or edit /etc/vscode/policy.json.
# Supply the real gallery SERVICE endpoint, not the marketplace home page.
python3 - "$@" <<'PYCODE'
import json, sys
from urllib.parse import urlsplit
if len(sys.argv) != 2:
    sys.exit("usage: provide your approved HTTPS gallery service URL")
url = sys.argv[1]
try:
    p = urlsplit(url)
    port = p.port
except ValueError:
    sys.exit("invalid gallery URL")
if (p.scheme != "https" or not p.hostname or p.username or p.password
        or p.query or p.fragment or p.netloc.endswith(":") or any(c.isspace() or ord(c) < 32 for c in url)):
    sys.exit("gallery URL must be HTTPS without credentials, query, fragment, or whitespace")
print(json.dumps({"ExtensionGalleryServiceUrl": url}, indent=2))
PYCODE
# HTH Guide Excerpt: end extension-marketplace
