#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: blueshift-2.1
#   guide:   https://howtoharden.com/guides/blueshift/
#   profile: L2
#   mode:    read-only
#   requires: BLUESHIFT_FROM_DOMAIN, Python 3.9+, dig, trusted DNS resolver
# First-party source: https://support-blueshift.blueconic.com/en/articles/810285-email-authentication-spf-dkim-dmarc
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
domain=${BLUESHIFT_FROM_DOMAIN:?Set the exact approved From domain}
python3 - "$domain" <<'PYTHON'
import json
import re
import shlex
import subprocess
import sys

domain = sys.argv[1].lower()
if (len(domain) > 253 or "." not in domain
        or any(not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?", label)
               for label in domain.split("."))):
    sys.exit("use an exact ASCII DNS domain with no final dot")
owner = "_dmarc." + domain + "."
try:
    reply = subprocess.run(
        ["dig", "-r", "+time=3", "+tries=1", "+noall", "+answer", owner, "TXT"],
        capture_output=True, text=True, check=True, timeout=10,
    )
except (OSError, subprocess.SubprocessError):
    sys.exit("DNS TXT lookup did not complete")
records = []
for line in reply.stdout.splitlines():
    item = line.split(maxsplit=4)
    if (len(item) != 5 or item[0].lower() != owner
            or item[2:4] != ["IN", "TXT"]):
        continue
    # Refuse escaped TXT presentation rather than guessing at DNS escape semantics.
    if not re.fullmatch(r'"[^"\\]*"(?:\s+"[^"\\]*")*', item[4]):
        sys.exit("unexpected TXT presentation")
    value = "".join(shlex.split(item[4]))
    if re.match(r"^v\s*=\s*DMARC1(?:\s*;|\s*$)", value, re.IGNORECASE):
        records.append(value)
if len(records) != 1:
    sys.exit("expected exactly one explicit DMARC TXT policy at the From domain")
tags = {}
for field in records[0].rstrip().removesuffix(";").split(";"):
    key, found, value = field.partition("=")
    key, value = key.strip().lower(), value.strip().lower()
    if not found or not key or not value or key in tags:
        sys.exit("ambiguous or malformed DMARC tags")
    tags[key] = value
policy = tags.get("p")
percent = tags.get("pct", "100")
matches = tags.get("v") == "dmarc1" and policy in {"quarantine", "reject"} and percent == "100"
print(json.dumps({"scope": "exact-dns-record-only", "from_domain": domain,
                  "policy": policy if policy in {"none", "quarantine", "reject"} else None,
                  "full_enforcement_requested": matches}))
sys.exit(0 if matches else 1)
PYTHON
# HTH Guide Excerpt: end read-evidence
