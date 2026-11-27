#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: tabnine-2.2
#   guide: https://howtoharden.com/guides/tabnine/#22-limit-indexed-repository-connections
#   profile: L2
#   mode: read-only
#   requires: bash, curl, jq, approved tenant origin and scoped Tabnine PAT
# HTH tabnine 2.2: Limit indexed repository connections
# Profile: L2 (Walk)
# Guide: https://howtoharden.com/guides/tabnine/
# Reference: https://raw.githubusercontent.com/codota/t9-api-yamls/refs/heads/main/docs/unified-tabnine-api.yaml
# HTH Guide Excerpt: begin sample-team-repository-inventory
set -euo pipefail
set +x
: "${TABNINE_BASE_URL:?Set the verified Tabnine tenant HTTPS origin}"
[[ "$TABNINE_BASE_URL" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[1-9][0-9]{0,4})?$ ]] ||
  { printf '%s\n' 'Supply an HTTPS origin with no path or credentials.' >&2; exit 2; }
: "${TABNINE_TEAM_ID:?Set the approved team UUID}"
[[ "$TABNINE_TEAM_ID" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]] || exit 2
: "${TABNINE_PAT:?Set the approved read-only API key}"
[[ "${TABNINE_PAT}" =~ ^[A-Za-z0-9._~-]+$ ]] ||
  { printf '%s\n' 'Invalid bearer token characters.' >&2; exit 2; }
printf 'header = "Authorization: Bearer %s"\n' "${TABNINE_PAT}" |
  curl --disable --config - --proto '=https' --fail --silent --show-error \
    --connect-timeout 10 --max-time 30 \
    "$TABNINE_BASE_URL/api/team/v1/$TABNINE_TEAM_ID/connections/repositories" |
  jq -e 'if type == "array" then {repository_count:length, repository_types: ([.[].repo_type] | group_by(.) | map({type: .[0], count:length}))} else error("Unexpected repository inventory") end'
# HTH Guide Excerpt: end sample-team-repository-inventory
