#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-4.5
#   guide: https://howtoharden.com/guides/factory/#45-scope-environment-secrets-and-persistent-compute-access
#   profile: L2
#   mode: read-only
#   requires: FACTORY_API_KEY(authorized organization identity), FACTORY_SECRET_NAMES_OUTPUT(new private file), bash, curl, jq, python3
# HTH Factory 4.5 — NIST AC-6, IA-5, CM-6
# Source: https://docs.factory.com/api-reference/organization (available; checked 2026-11-05)
# The documented response contains names only. No pagination contract is published for this route.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-computer-secret-names
hth_api_init 2
[[ -n "${FACTORY_SECRET_NAMES_OUTPUT:-}" ]] || hth_unknown 'provide FACTORY_SECRET_NAMES_OUTPUT'
hth_get '/api/v0/organization/computer-secrets' "$HTH_TEMP/response.json"
jq -e '(.secrets | type == "array") and
  all(.secrets[]; type == "object" and (.key | type == "string" and length > 0)) and
  ((.secrets | map(.key) | unique | length) == (.secrets | length))' \
  "$HTH_TEMP/response.json" >/dev/null || hth_unknown 'invalid or overlapping secret-name inventory'
# Persist only the documented metadata even if a future server adds fields.
jq '{secrets: [.secrets[] | {key: .key}]}' "$HTH_TEMP/response.json" > "$HTH_TEMP/names.json"
hth_save_private "$HTH_TEMP/names.json" "$FACTORY_SECRET_NAMES_OUTPUT"
printf 'COLLECTED: %s Computer secret names. Values and workload access were not read or changed.\n' \
  "$(jq '.secrets | length' "$HTH_TEMP/names.json")"
# HTH Guide Excerpt: end inventory-computer-secret-names
