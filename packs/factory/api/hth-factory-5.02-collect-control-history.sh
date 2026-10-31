#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-5.2
#   guide: https://howtoharden.com/guides/factory/#52-review-audit-events-and-managed-policy-history
#   profile: L2
#   mode: read-only
#   requires: FACTORY_API_KEY(human admin credential authorized to read control history), FACTORY_HISTORY_OUTPUT(new private file), bash, curl, jq, python3
# HTH Factory 5.2 — NIST AU-6, CM-3
# Source: https://docs.factory.com/api-reference/organization (available; verified 2026-10-30)
# This is managed-settings revision history, NOT the complete organization audit log.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin collect-control-history
hth_api_init 2
[[ -n "${FACTORY_HISTORY_OUTPUT:-}" ]] || hth_unknown 'set FACTORY_HISTORY_OUTPUT to a new private file'
hth_paginate '/api/v0/organization/enterprise-controls/history' changes "$HTH_TEMP/changes.jsonl"
jq -se 'all(.[]; (.revision | type == "number") and (.revision == (.revision | floor)) and
  (.settings | type == "object") and (.user | type == "object") and (.updatedAt | type == "string")) and
  ((map(.revision) | unique | length) == length)' "$HTH_TEMP/changes.jsonl" >/dev/null ||
  hth_unknown 'invalid or overlapping revision history'
jq -s '{changes: .}' "$HTH_TEMP/changes.jsonl" > "$HTH_TEMP/history.json"
hth_save_private "$HTH_TEMP/history.json" "$FACTORY_HISTORY_OUTPUT"
printf 'COLLECTED: %s settings revisions. Historical snapshots do not prove effective device policy or full audit coverage.\n' \
  "$(jq -s 'length' "$HTH_TEMP/changes.jsonl")"
# HTH Guide Excerpt: end collect-control-history
