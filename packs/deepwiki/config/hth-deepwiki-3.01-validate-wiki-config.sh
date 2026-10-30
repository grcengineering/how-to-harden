#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: deepwiki-3.1
#   guide: https://howtoharden.com/guides/deepwiki/#31-review-wiki-generation-configuration-as-repository-content
#   profile: L2
#   mode: read-only
#   requires: python3, .devin/wiki.json path, --enterprise(optional)
# HTH DeepWiki 3.1: Validate repository-native wiki configuration
# Profile Level: L2 (Walk) | NIST 800-53: CM-3, CM-6
# Source: https://docs.devin.ai/work-with-devin/deepwiki
# Status: available; checked 2026-10-29.
# Vendor limits: 30 pages (80 Enterprise), 100 notes total, 10,000 chars/note.
# HTH additional policy: nonblank purpose, reject unknown keys, dangling
# parent references and cycles. These are local review checks, not an ACL.
# Vendor docs do not specify page_notes item structure. Nonempty page_notes
# returns UNKNOWN for manual review, rather than inventing a complete schema.
# Does not print note/page content. An absent file is valid operationally but
# cannot be assessed by this command (exit 2), not a failing deployment.

# HTH Guide Excerpt: begin validate-wiki-config
set -euo pipefail
if [[ $# -lt 1 || $# -gt 2 || ( $# -eq 2 && "$2" != "--enterprise" ) ]]; then
  echo "Usage: $0 /path/to/.devin/wiki.json [--enterprise]" >&2
  exit 2
fi
command -v python3 >/dev/null 2>&1 || { echo "PRECONDITION: python3 required" >&2; exit 2; }
python3 - "$@" <<'PY'
import json
import sys

def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key")
        result[key] = value
    return result

try:
    with open(sys.argv[1], encoding="utf-8") as source:
        raw = source.read(4 * 1024 * 1024 + 1)
    if len(raw) > 4 * 1024 * 1024:
        raise ValueError("oversized input")
    config = json.loads(raw, object_pairs_hook=unique_object)
except (OSError, UnicodeError, ValueError, RecursionError):
    print("UNKNOWN: file is unreadable, oversized, or invalid JSON", file=sys.stderr)
    sys.exit(2)

def fail(message):
    print("FINDING: " + message)
    sys.exit(1)

def nonblank(value):
    return isinstance(value, str) and bool(value.strip())

if not isinstance(config, dict) or set(config) != {"repo_notes", "pages"}:
    fail("required top-level keys are repo_notes and pages; unknown keys need review")
notes = config["repo_notes"]
pages = config["pages"]
max_pages = 80 if len(sys.argv) == 3 else 30
if not isinstance(notes, list) or not isinstance(pages, list) or not 1 <= len(pages) <= max_pages:
    fail("notes/pages must be arrays with 1 to the plan's maximum pages")

all_notes = list(notes)
has_page_notes = False
parents = {}
for page in pages:
    if not isinstance(page, dict) or not set(page) <= {"title", "purpose", "parent", "page_notes"}:
        fail("invalid or unrecognized page fields")
    title, purpose = page.get("title"), page.get("purpose")
    if not nonblank(title) or not nonblank(purpose) or title in parents:
        fail("page titles must be unique and nonblank; purposes must be nonblank")
    parent = page.get("parent")
    if parent is not None and not nonblank(parent):
        fail("parent must be null or a nonblank page title")
    parents[title] = parent
    page_notes = page.get("page_notes", [])
    if not isinstance(page_notes, list):
        fail("page_notes must be an array")
    has_page_notes = has_page_notes or bool(page_notes)
    all_notes.extend(page_notes)

if len(all_notes) > 100:
    fail("combined repo and page notes exceed 100")
for note in notes:
    if not isinstance(note, dict) or not set(note) <= {"content", "author"}:
        fail("invalid or unrecognized note fields")
    content = note.get("content")
    if not isinstance(content, str) or len(content) > 10000:
        fail("note content must be a string of at most 10000 characters")
    if "author" in note and not isinstance(note["author"], str):
        fail("note author must be a string")

if has_page_notes:
    print("UNKNOWN: nonempty page_notes require manual review; item schema is not fully documented")
    sys.exit(2)

for title in parents:
    seen = set()
    current = title
    while current is not None:
        if current not in parents or current in seen:
            fail("HTH hierarchy check: dangling parent or cycle")
        seen.add(current)
        current = parents[current]

print(f"PASS: structural checks passed for {len(pages)} page(s) and {len(all_notes)} note(s)")
print("NOT PROVEN: prose safety, generated accuracy, secret exclusion, or access control")
PY
# HTH Guide Excerpt: end validate-wiki-config
