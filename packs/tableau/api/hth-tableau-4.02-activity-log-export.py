#!/usr/bin/env python3
# HTH Tableau Control 4.2: Collect the Activity Log
# Profile: L2 | NIST 800-53: AU-2, AU-6, AU-11
# https://howtoharden.com/guides/tableau/#42-collect-the-activity-log
#
# Downloads Tableau Cloud Activity Log files (tenant events) through the
# Tableau Cloud Manager REST API for retention and SIEM forwarding.
#   TCM sign-in:  POST https://cloudmanager.tableau.com/api/v1/pat/login
#                 body {"token": "<PAT secret>"}; response carries sessionToken
#                 and tenantId; later requests use x-tableau-session-token
#                 https://help.tableau.com/current/api/cloud-manager/en-us/docs/authentication.html
#   List files:   GET https://cloudmanager.tableau.com/api/v1/tenants/{tenantId}/activitylog
#                 ?startTime=...&endTime=... (UTC; max 7-day span)
#   Download URLs: POST the same URI with body {"files": [<paths>]} — returns
#                 short-lived (10 minute) download URLs
#                 https://help.tableau.com/current/api/cloud-manager/en-us/docs/platform_data.html
#
# Requires a Tableau Cloud Manager personal access token (Cloud Administrator).
# Environment: TCM_PAT_SECRET, START_TIME / END_TIME (UTC, max 7-day span),
#   OUT_DIR (default ./activity-log).
import json
import os
import pathlib
import urllib.parse
import urllib.request

TCM = "https://cloudmanager.tableau.com/api/v1"


def tcm_request(url, session_token=None, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data)
    req.add_header("Content-Type", "application/json")
    if session_token:
        req.add_header("x-tableau-session-token", session_token)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


# HTH Guide Excerpt: begin api-tcm-signin
# Sign in to Tableau Cloud Manager with a PAT secret. The response returns the
# session token (valid 4 hours, 30-minute idle limit) and the tenant id used
# in every activity-log URI.
def tcm_sign_in():
    body = tcm_request(f"{TCM}/pat/login", payload={"token": os.environ["TCM_PAT_SECRET"]})
    return body["sessionToken"], body["tenantId"]
# HTH Guide Excerpt: end api-tcm-signin


# HTH Guide Excerpt: begin api-download-activity-log
# List the tenant-event activity log files for a window (max 7 days), exchange
# the paths for short-lived download URLs, and save each JSON file locally.
# The download URLs are unauthenticated and expire in 10 minutes — treat them
# as sensitive and download immediately.
def download_activity_log(session_token, tenant_id, start_time, end_time, out_dir):
    base = f"{TCM}/tenants/{tenant_id}/activitylog"
    window = urllib.parse.urlencode({"startTime": start_time, "endTime": end_time})
    files = tcm_request(f"{base}?{window}", session_token=session_token)
    paths = [f["path"] for f in files]
    print(f"Activity log files in window: {len(paths)}")
    if not paths:
        return 0

    urls = tcm_request(base, session_token=session_token, payload={"files": paths})
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for entry in urls:
        target = out / entry["path"].replace("/", "_")
        with urllib.request.urlopen(entry["url"]) as resp:
            target.write_bytes(resp.read())
        print(f"  saved {target}")
    return len(paths)
# HTH Guide Excerpt: end api-download-activity-log


def main():
    start_time = os.environ["START_TIME"]  # UTC, e.g. 2026-08-01T00:00:00Z
    end_time = os.environ["END_TIME"]      # UTC, max 7 days after START_TIME
    out_dir = os.environ.get("OUT_DIR", "activity-log")
    session_token, tenant_id = tcm_sign_in()
    count = download_activity_log(session_token, tenant_id, start_time, end_time, out_dir)
    print(f"Done: {count} file(s) downloaded to {out_dir}")


if __name__ == "__main__":
    main()
