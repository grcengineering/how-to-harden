#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: factory-1.4
#   guide: https://howtoharden.com/guides/factory/#14-reconcile-group-and-individual-policy-overrides
#   profile: L2
#   mode: read-only
#   requires: FACTORY_API_KEY(human Manager or Owner), FACTORY_GROUP_LIMITS_OUTPUT(new private file), bash, curl, jq, python3
# Source: https://docs.factory.com/api-reference/organization (available; verified 2026-11-14)
# Group credit mappings only: not membership, model overrides or effective user policy.
set +x
set -Eeuo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# HTH Guide Excerpt: begin inventory-group-limits
hth_api_init 2
[[ -n "${FACTORY_GROUP_LIMITS_OUTPUT:-}" ]] || hth_unknown 'set FACTORY_GROUP_LIMITS_OUTPUT to a new private file'
hth_get '/api/v0/organization/usage/limits/groups' "$HTH_TEMP/groups.json"
# The current response is not paginated. Refuse an unfamiliar paging envelope.
jq -e '(.groupLimits | type == "array") and
  (has("pagination") or has("nextCursor") | not) and
  all(.groupLimits[];
    (.groupId | type == "string" and length > 0) and
    has("name") and (.name == null or (.name | type == "string")) and
    has("limit") and (.limit == null or
      (.limit | type == "number" and . >= 0 and . == floor))) and
  (([.groupLimits[].groupId] | unique | length) == (.groupLimits | length))' \
  "$HTH_TEMP/groups.json" >/dev/null 2>&1 || hth_unknown 'invalid, duplicate or partial group credit mappings'
jq '{groupLimits: [.groupLimits[] | {groupId, name, limit}]}' \
  "$HTH_TEMP/groups.json" > "$HTH_TEMP/inventory.json"
hth_save_private "$HTH_TEMP/inventory.json" "$FACTORY_GROUP_LIMITS_OUTPUT"
printf 'COLLECTED: %s group credit mappings; review model-only groups, membership and individual overrides in the console.\n' \
  "$(jq '.groupLimits | length' "$HTH_TEMP/inventory.json")"
# HTH Guide Excerpt: end inventory-group-limits
