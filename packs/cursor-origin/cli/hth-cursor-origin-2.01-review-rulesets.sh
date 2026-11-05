#!/usr/bin/env bash
# HTH Pack Contract: v1
# control: cursor-origin-2.1
# guide: https://howtoharden.com/guides/cursor-origin/#21-enforce-native-merge-and-push-rulesets
# profile: L1
# mode: read-only
# requires: origin(early beta); HTH_ALLOW_READONLY=1; ORIGIN_REPO(owner/repo)
# NIST AC-3. Source: https://cursor.com/docs/origin/cli/reference/commands (2026-11-05)
# Usage: HTH_ALLOW_READONLY=1 ORIGIN_REPO=owner/repo bash <file>
# Reads only. No ruleset creation/import/update/deletion and no credential output.
set -euo pipefail
[[ ${HTH_ALLOW_READONLY:-} == 1 ]] || { echo 'PRECONDITION: set HTH_ALLOW_READONLY=1 after authorizing a read'; exit 2; }
[[ ${ORIGIN_REPO:-} =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || { echo 'PRECONDITION: explicit owner/repo required'; exit 2; }
[[ -z ${CURSOR_ORIGIN_ENDPOINT:-} ]] || { echo 'PRECONDITION: unset custom Origin endpoint before using stored credentials'; exit 2; }
command -v origin >/dev/null || { echo 'PRECONDITION: install and authenticate the official Origin CLI separately'; exit 2; }
# HTH Guide Excerpt: begin review-enforcement-ref-and-bypass
origin ruleset list -R "$ORIGIN_REPO" --json name,enforcement,kind,includedRefNames,excludedRefNames,rules,bypassActors
echo 'REVIEW: active enforcement, intended refs/rules and bypass identities need manual reconciliation; evaluate mode does not block.'
# HTH Guide Excerpt: end review-enforcement-ref-and-bypass
