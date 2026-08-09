#!/usr/bin/env python3
# =============================================================================
# HTH Duo Control 6.1: Enable Logging and Alerting
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2, AU-6
# https://howtoharden.com/guides/duo/#61-enable-logging-and-alerting
#
# Exports authentication log events as JSON Lines for SIEM ingestion via the
# official Duo Admin API Python SDK (pip install duo-client). Uses
# GET /admin/v2/logs/authentication through get_authentication_log
# (api_version=2), which takes mintime/maxtime as Unix timestamps in
# milliseconds and paginates via metadata.next_offset. Requires an Admin API
# application with "Grant read log" permission.
# Docs: https://duo.com/docs/adminapi
# =============================================================================
import json
import os
import sys
import time

import duo_client

# HTH Guide Excerpt: begin sdk-export-authentication-logs
admin_api = duo_client.Admin(
    ikey=os.environ["DUO_IKEY"],
    skey=os.environ["DUO_SKEY"],
    host=os.environ["DUO_API_HOST"],
)

# Window defaults to the last 24 hours; both bounds are Unix ms timestamps.
now_s = int(time.time())
mintime = int(os.environ.get("DUO_LOG_MINTIME_MS", (now_s - 86400) * 1000))
maxtime = int(os.environ.get("DUO_LOG_MAXTIME_MS", now_s * 1000))

next_offset = None
exported = 0
while True:
    response = admin_api.get_authentication_log(
        api_version=2,
        mintime=mintime,
        maxtime=maxtime,
        next_offset=next_offset,
    )
    for event in response["authlogs"]:
        sys.stdout.write(json.dumps(event) + "\n")
        exported += 1
    next_offset = (response.get("metadata") or {}).get("next_offset")
    if not next_offset:
        break

print(f"exported {exported} authentication event(s)", file=sys.stderr)
# HTH Guide Excerpt: end sdk-export-authentication-logs
