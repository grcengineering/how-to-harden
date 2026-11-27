# HTH Pack Contract: v1
#   control: aqua-security-2.1
#   guide: https://howtoharden.com/guides/aqua-security/
#   profile: L1
#   mode: read-only
#   requires: Python 3; AQUA_API_KEY and AQUA_API_SECRET for Wave/CSPM
# HTH Guide Excerpt: begin audit-cloud-account-sample
import hashlib
import hmac
import json
import os
import sys
import time
from urllib import error, request

HOST = "https://api.cloudsploit.com"
RESOURCE = "/v2/keys"
MAX_BYTES = 4 * 1024 * 1024


class NoRedirect(request.HTTPRedirectHandler):
    """Never send signed authentication headers to a redirect destination."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def account_summary(opener, key, secret, now_ms):
    signature = hmac.new(
        secret.encode("utf-8"),
        f"{now_ms}GET{RESOURCE}".encode("ascii"),
        hashlib.sha256,
    ).hexdigest()
    query = request.Request(HOST + RESOURCE, method="GET", headers={
        "Accept": "application/json",
        "X-API-Key": key,
        "X-Signature": signature,
        "X-Timestamp": str(now_ms),
    })
    with opener.open(query, timeout=30) as response:
        raw = response.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise ValueError("Response exceeded the supported evidence sample size")
    payload = json.loads(raw)
    accounts = payload.get("data") if isinstance(payload, dict) else None
    if not isinstance(accounts, list):
        raise ValueError("Unexpected Aqua CSPM response")
    providers = {}
    for row in accounts:
        if not isinstance(row, dict) or not isinstance(row.get("cloud"), str):
            raise ValueError("Unexpected Aqua cloud account schema")
        cloud = row["cloud"].lower()
        category = cloud if cloud in {"aws", "azure", "gcp", "oci"} else "other"
        providers[category] = providers.get(category, 0) + 1
    return {"returnedCount": len(accounts), "byProvider": providers}


def main():
    key = os.environ.get("AQUA_API_KEY")
    secret = os.environ.get("AQUA_API_SECRET")
    if not key or not key.isascii() or any(ord(ch) < 33 or ord(ch) > 126 for ch in key) or not secret:
        raise SystemExit("Set valid AQUA_API_KEY and AQUA_API_SECRET via your secret manager.")
    try:
        result = account_summary(request.build_opener(NoRedirect()), key, secret, time.time_ns() // 1_000_000)
    except (OSError, ValueError, error.URLError):
        print("Aqua CSPM account read failed. Verify the endpoint, credentials, and response contract.", file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
# HTH Guide Excerpt: end audit-cloud-account-sample
