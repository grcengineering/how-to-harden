"""Shared Assembled REST transport; invoked by the adjacent bash+curl packs.

Reference: https://docs.assembled.com/ (fetched 2026-11-16).
Never prints raw responses, credentials, names or email addresses.
"""
import json
import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


class PackError(Exception):
    pass


def request(path, key):
    # The key goes over stdin, never argv, curlrc, a URL, or a persistent file.
    args = ["curl", "-q", "--silent", "--proto", "=https", "--noproxy", "*",
            "--connect-timeout", "15", "--max-time", "60",
            "--max-filesize", "20971520", "--config", "-",
            "--request", "GET", "--header", "Accept: application/json",
            "--write-out", "\n%{http_code}",
            "--url", "https://api.assembledhq.com" + path]
    try:
        result = subprocess.run(args, input=f'user = "{key}:"\n', text=True,
                                capture_output=True, timeout=65, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise PackError("Transport failed; no report emitted.") from exc
    if result.returncode:
        raise PackError("Transport failed; no report emitted.")
    body, _, status = result.stdout.rpartition("\n")
    if status != "200":
        raise PackError("Unexpected HTTP status; no report emitted (check access or rate limits).")
    try:
        data = json.loads(body)
    except (ValueError, TypeError) as exc:
        raise PackError("Response was not JSON; no report emitted.") from exc
    if not isinstance(data, dict):
        raise PackError("Expected an object response.")
    return data


def objects(data, kind):
    value = data.get(kind)
    if not isinstance(value, dict):
        raise PackError("Unexpected collection shape: " + kind)
    for ident, row in value.items():
        if not isinstance(row, dict) or row.get("id") != ident:
            raise PackError("Invalid collection identity: " + kind)
    return value


def collect(path, kind, key, query=""):
    rows = {}
    expected = None
    offset = 0
    for _ in range(1000):
        data = request(f"{path}?limit=100&offset={offset}{query}", key)
        page = objects(data, kind)
        total = data.get("total")
        if type(total) is not int or total < 0:
            raise PackError("Missing or invalid total; completeness cannot be established.")
        if expected is not None and total != expected:
            raise PackError("Collection changed during pagination; rerun for a stable snapshot.")
        expected = total
        if len(page) > 100 or set(page) & set(rows):
            raise PackError("Repeated or oversized page; no report emitted.")
        rows.update(page)
        if len(rows) == total:
            return rows
        if len(rows) > total or not page:
            raise PackError("Incomplete or inconsistent pagination; no report emitted.")
        offset += len(page)
    raise PackError("Page limit exceeded; narrow the collection.")


def roles_report(key):
    roles = objects(request("/v0/roles", key), "roles")
    people = collect("/v0/people", "people", key)
    counts = Counter()
    unknown = 0
    for person in people.values():
        assigned = person.get("roles")
        if not isinstance(assigned, list) or not all(isinstance(x, str) for x in assigned):
            raise PackError("Missing role assignments; no report emitted.")
        if len(assigned) != 1 or any(role not in roles for role in assigned):
            unknown += 1
        counts.update(assigned)
    if not all(isinstance(role.get("name"), str) for role in roles.values()):
        raise PackError("Role name is missing.")
    print(json.dumps({"result": "REVIEW", "people_returned": len(people),
                      "ambiguous_or_unknown_role_assignments": unknown,
                      "roles": [{"id": ident, "name": role["name"],
                                 "assigned_people": counts[ident]}
                                for ident, role in sorted(roles.items())],
                      "limitation": "Role membership only; permissions, SSO and account sign-in state are not exposed here."}, indent=2))


def leavers_report(key, filename):
    emails = {line.strip().casefold() for line in Path(filename).read_text().splitlines()
              if line.strip()}
    if not emails or any("@" not in email for email in emails):
        raise PackError("Provide a private, nonempty file with one departed email address per line.")
    people = collect("/v0/people", "people", key, "&include_deleted=true")
    matched = []
    for ident, person in people.items():
        if not isinstance(person.get("email"), str) or type(person.get("deleted")) is not bool:
            raise PackError("Missing directory fields; no report emitted.")
        if person["email"].casefold() in emails:
            matched.append({"person_id": ident, "deleted": person["deleted"]})
    print(json.dumps({"result": "REVIEW", "departed_addresses_supplied": len(emails),
                      "matching_directory_records": matched,
                      "limitation": "deleted is soft-deletion, not a login/deactivation signal. Verify deactivation and session denial in the console."}, indent=2))


def event_report(key):
    start = os.environ.get("ASSEMBLED_START_TIME", "")
    end = os.environ.get("ASSEMBLED_END_TIME", "")
    if not re.fullmatch(r"[0-9]{1,11}", start) or not re.fullmatch(r"[0-9]{1,11}", end):
        raise PackError("Set ASSEMBLED_START_TIME and ASSEMBLED_END_TIME to Unix seconds.")
    if not 0 < int(end) - int(start) <= 31 * 86400:
        raise PackError("Use a positive window of at most 31 days per collection.")
    rows = collect("/v0/event_changes", "event_changes", key,
                   f"&start_time={start}&end_time={end}")
    output = []
    for ident, row in rows.items():
        actor = row.get("modified_by")
        if (type(row.get("modified_at")) is not int
                or not isinstance(row.get("event_change_type"), str)
                or not isinstance(actor, dict) or not isinstance(actor.get("id"), str)):
            raise PackError("Missing event fields; no report emitted.")
        output.append({"id": ident, "modified_at": row["modified_at"],
                       "modified_by": {"id": actor["id"]},
                       "event_change_type": row["event_change_type"]})
    # Buffer until all pages and fields validate; failure never emits a partial report.
    for row in sorted(output, key=lambda x: (x["modified_at"], x["id"])):
        print(json.dumps(row, separators=(",", ":")))


def main():
    key = os.environ.pop("ASSEMBLED_API_KEY", "")
    if not re.fullmatch(r"sk_live_[A-Za-z0-9_-]+", key):
        raise PackError("Missing or invalid ASSEMBLED_API_KEY.")
    if len(sys.argv) == 2 and sys.argv[1] == "roles":
        roles_report(key)
    elif len(sys.argv) == 3 and sys.argv[1] == "leavers":
        leavers_report(key, sys.argv[2])
    elif len(sys.argv) == 2 and sys.argv[1] == "events":
        event_report(key)
    else:
        raise PackError("Unexpected arguments.")


if __name__ == "__main__":
    try:
        main()
    except (PackError, OSError, UnicodeError) as error:
        # Never echo an exception containing request bodies, credentials or roster values.
        if isinstance(error, PackError):
            print("Assembled pack: " + str(error), file=sys.stderr)
        else:
            print("Assembled pack: local input could not be read.", file=sys.stderr)
        sys.exit(1)
