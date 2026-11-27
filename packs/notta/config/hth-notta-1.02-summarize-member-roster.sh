#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: notta-1.2
#   guide: https://howtoharden.com/guides/notta/#12-review-privileged-workspace-roles
#   profile: L1
#   mode: read-only
#   requires: Bash, Python 3, English Enterprise Current Member List
# HTH notta 1.2: Review privileged workspace roles
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/notta/#12-review-privileged-workspace-roles
# Reference: https://support.notta.ai/hc/en-us/articles/41864234547099-Unified-management-based-on-member-list-Invite-Remove-and-Update
# HTH Guide Excerpt: begin summarize-member-roster
set -euo pipefail
if [[ $# -ne 1 ]]; then
  printf 'Usage: summarize-member-roster CURRENT_MEMBER_LIST.csv\n' >&2
  exit 2
fi
python3 - "$1" <<'PACKPY'
import collections
import csv
import json
import sys

def read_roster(path):
    counts = collections.Counter()
    seen = set()
    with open(path, encoding="utf-8-sig", newline="") as roster:
        reader = csv.reader(
            (line for line in roster if not line.startswith("#")), strict=True
        )
        fields = next(reader, [])
        if sorted(fields) != ["Email", "Group", "Role"]:
            raise ValueError("unexpected header")
        i_email, i_role = fields.index("Email"), fields.index("Role")
        for row in reader:
            if not row:
                continue
            if len(row) != len(fields):
                raise ValueError("unexpected column count")
            email, role = row[i_email], row[i_role]
            local, delim, domain = email.rpartition("@")
            if not delim or not local or not domain or "@" in local or any(c.isspace() for c in email):
                raise ValueError("invalid member email")
            if role not in {"Owner", "Admin", "Member"} or email.casefold() in seen:
                raise ValueError("unexpected role or duplicate member")
            seen.add(email.casefold())
            counts[role] += 1
    if counts["Owner"] != 1:
        raise ValueError("one workspace Owner expected")
    return {role.lower(): counts[role] for role in ("Owner", "Admin", "Member")}

try:
    print(json.dumps(read_roster(sys.argv[1]), sort_keys=True))
except (OSError, UnicodeError, csv.Error, ValueError) as exc:
    # CSV exceptions can contain sensitive values; never echo input or a file name.
    print("Could not verify roster: " + type(exc).__name__, file=sys.stderr)
    raise SystemExit(1) from None
PACKPY
# HTH Guide Excerpt: end summarize-member-roster
