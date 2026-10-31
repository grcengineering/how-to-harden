#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-1.2
#   guide: https://howtoharden.com/guides/factory/#12-govern-directory-sync-membership-and-roles
#   profile: L1
#   mode: read-only
#   requires: FACTORY_API_KEY(human credential authorized to list organization users), FACTORY_MEMBERS_OUTPUT(new private file), bash, curl, jq, python3
# HTH Factory 1.2 — NIST AC-2, AC-6
# Source: https://docs.factory.com/api-reference/organization (available; verified 2026-10-30)
# Inventory only: the documented user response does not establish roles or SCIM ownership.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-members
hth_api_init 1
[[ -n "${FACTORY_MEMBERS_OUTPUT:-}" ]] || hth_unknown 'set FACTORY_MEMBERS_OUTPUT to a new private file'
hth_paginate '/api/v0/organization/users' users "$HTH_TEMP/users.jsonl"
jq -se 'all(.[]; (.id | type == "string" and length > 0) and (.email | type == "string")) and
  ((map(.id) | unique | length) == length)' "$HTH_TEMP/users.jsonl" >/dev/null ||
  hth_unknown 'invalid or duplicate user records'
jq -s '{users: .}' "$HTH_TEMP/users.jsonl" > "$HTH_TEMP/inventory.json"
hth_save_private "$HTH_TEMP/inventory.json" "$FACTORY_MEMBERS_OUTPUT"
printf 'COLLECTED: %s organization users; compare private evidence with IdP assignments and console roles.\n' \
  "$(jq -s 'length' "$HTH_TEMP/users.jsonl")"
# HTH Guide Excerpt: end inventory-members
