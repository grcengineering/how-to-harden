#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: inspect-2.1
#   guide: https://howtoharden.com/guides/inspect/#21-limit-connected-github-repositories
#   profile: L1
#   mode: read-only
#   requires: bash, curl, jq, python3, INSPECT_API_KEY with target access
# HTH 2.1: Limit Connected GitHub Repositories
# Profile: L1 | NIST SP 800-53 AC-6 | https://howtoharden.com/guides/inspect/
# Sources: https://docs.inspect.com/api/openapi.json (2026-11-17; available v2 routes).
# No live tenant validation. Download common.sh beside this file.
# HTH Guide Excerpt: begin inventory-repositories
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
hth_init
hth_request GET /api/v2/repositories "$HTH_TEMP/repos.json"
jq -e '(.data|type)=="array" and (.meta.has_next_page|type)=="boolean" and all(.data[]; (.id|type)=="string" and (.name|type)=="string" and (.organization|type)=="string" and (.auto_match_enabled|type)=="boolean" and (.automatic_reviews|type)=="string")' "$HTH_TEMP/repos.json" >/dev/null || hth_unknown 'malformed repository list'
# This endpoint documents no cursor parameters, despite its generic pagination metadata.
[[ $(jq -r '.meta.has_next_page' "$HTH_TEMP/repos.json") == false ]] || hth_unknown 'repository list truncated; no documented pagination request parameter'
jq '{scope:"Repositories visible to this credential only, not GitHub installation completeness",repositories:[.data[]|{id,name,organization,auto_match_enabled,automatic_reviews}]}' "$HTH_TEMP/repos.json" > "$HTH_TEMP/output.json"
hth_save "$HTH_TEMP/output.json"
printf 'COLLECTED: %s visible repositories; compare with GitHub installation selection.\n' "$(jq '.data|length' "$HTH_TEMP/repos.json")"
# HTH Guide Excerpt: end inventory-repositories
