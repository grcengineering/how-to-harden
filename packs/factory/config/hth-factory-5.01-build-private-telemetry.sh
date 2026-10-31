#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-5.1
#   guide: https://howtoharden.com/guides/factory/#51-export-telemetry-without-raw-message-content
#   profile: L2
#   mode: read-only
#   requires: FACTORY_OTLP_ENDPOINT(approved HTTPS collector base URL), bash, jq, python3; deploy FACTORY_OTLP_TOKEN separately to managed devices
# HTH Factory 5.1 — NIST AU-2, AU-9, AC-4
# Sources: https://docs.factory.com/enterprise/telemetry
#          https://docs.factory.com/enterprise/telemetry/privacy (available; verified 2026-10-30)
# Emits policy only; the collector token is a literal reference, never resolved here.
set +x
set -Eeuo pipefail
# shellcheck source=../common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

# HTH Guide Excerpt: begin build-private-telemetry
hth_init 2
[[ -n "${FACTORY_OTLP_ENDPOINT:-}" ]] || hth_unknown 'provide FACTORY_OTLP_ENDPOINT'
python3 - <<'PY'
import json
import os
import sys
from urllib.parse import urlsplit
endpoint = os.environ['FACTORY_OTLP_ENDPOINT']
try:
    parsed = urlsplit(endpoint)
    if (parsed.scheme != 'https' or not parsed.hostname or parsed.username is not None or
        parsed.password is not None or parsed.query or parsed.fragment or
        any(c.isspace() or ord(c) < 32 for c in endpoint) or '\\' in endpoint):
        raise ValueError()
    parsed.port
except ValueError:
    print('UNKNOWN: collector must be HTTPS with no user info, query or fragment', file=sys.stderr)
    sys.exit(2)
print(json.dumps({'telemetry': {
    'enabled': True, 'endpoint': endpoint,
    'headers': {'Authorization': 'Bearer ${FACTORY_OTLP_TOKEN}'},
    'metricExportIntervalMs': 60000, 'logMessageContent': False,
    'granularity': 'aggregate', 'format': 'genai'
}}, indent=2))
PY
# HTH Guide Excerpt: end build-private-telemetry
