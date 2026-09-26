#!/usr/bin/env bash
# HTH GitHub Control 3.33: Audit Workflows for Cache Poisoning Risk
# Profile: L2 | NIST: SI-7, SA-12
# https://howtoharden.com/guides/github/#316-prevent-github-actions-cache-poisoning
#
# Local, read-only audit of a checked-out repository. Exits 1 when a finding exists.
set -euo pipefail

# HTH Guide Excerpt: begin audit-cache-writes
# 1. Workflows triggered by untrusted events that save caches
# 2. Cache keys built from attacker-controlled values
cd "${1:-.}"
[ -d .github/workflows ] || { echo "No .github/workflows directory in $(pwd) — nothing was audited" >&2; exit 2; }
FINDINGS=0
SCANNED=0
# Process substitution, not here-strings: a here-string needs a temp file, and if
# that fails the inner loop silently reads nothing and the audit reports 0.
while IFS= read -r wf; do
  SCANNED=$((SCANNED + 1))
  # Match every trigger spelling: block (`pull_request_target:`), inline
  # (`on: pull_request_target`) and list (`on: [push, pull_request_target]`).
  if grep -qE '(^|[^A-Za-z0-9_.])(pull_request_target|workflow_run|issue_comment)([^A-Za-z0-9_]|$)' "${wf}"; then
    while IFS= read -r hit; do
      [ -n "${hit}" ] || continue
      echo "  [UNTRUSTED-TRIGGER CACHE] ${wf}:${hit}"
      FINDINGS=$((FINDINGS + 1))
    done < <(grep -nE 'actions/cache(/save)?@|cache:[[:space:]]*(npm|pip|yarn|pnpm|gradle|maven)' "${wf}" || true)
  fi
  while IFS= read -r hit; do
    [ -n "${hit}" ] || continue
    echo "  [TAINTED CACHE KEY] ${wf}:${hit}"
    FINDINGS=$((FINDINGS + 1))
  done < <(grep -nE 'key:.*(github\.head_ref|github\.event\.pull_request|github\.event\.comment)' "${wf}" || true)
done < <(find .github/workflows \( -name '*.yml' -o -name '*.yaml' \))
echo "Workflow files scanned: ${SCANNED}"
[ "${SCANNED}" -gt 0 ] || { echo "No workflow files found — nothing was audited" >&2; exit 2; }
echo "Cache poisoning findings: ${FINDINGS}"
[ "${FINDINGS}" -eq 0 ] || exit 1
# HTH Guide Excerpt: end audit-cache-writes
