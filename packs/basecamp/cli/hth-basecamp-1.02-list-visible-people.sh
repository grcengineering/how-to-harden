#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: basecamp-1.2
#   guide:   https://howtoharden.com/guides/basecamp/
#   profile: L1
#   mode:    read-only
#   requires: BASECAMP_REVIEW_ACCOUNT_ID, pre-authenticated basecamp CLI, jq
# API/CLI source: https://github.com/basecamp/basecamp-cli/blob/main/internal/commands/people.go
# HTH Guide Excerpt: begin read-evidence
set +x
set -euo pipefail
# Run from a trusted directory with no project defaults in the selected profile.
# This only inventories caller-visible account people; it does not resolve board/project access.
account=${BASECAMP_REVIEW_ACCOUNT_ID:?Set the exact Basecamp account ID}
[[ "$account" =~ ^[1-9][0-9]*$ ]] || exit 2
basecamp --account "$account" people list --all --json |
  jq -ce --arg account "$account" '
    if .ok == true and (.data|type=="array") and all(.data[]; (.id|type=="string" or type=="number"))
    then {requested_account:$account, people:[.data[] | {id,admin,employee,client}]}
    else error("invalid people result") end
  '
# HTH Guide Excerpt: end read-evidence
