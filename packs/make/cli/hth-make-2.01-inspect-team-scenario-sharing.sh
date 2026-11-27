#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: make-2.1
#   guide: https://howtoharden.com/guides/make/#21-turn-off-public-sharing-for-internal-scenarios
#   profile: L1
#   mode: read-only
#   requires: Bash, make-cli, jq, scoped Make token and approved zone/team
# HTH make 2.1: Turn off public sharing for internal scenarios
# Profile: L1 (Crawl)
# Guide: https://howtoharden.com/guides/make/
# Reference: https://developers.make.com/make-cli/make-cli-reference/scenarios
# HTH Guide Excerpt: begin inspect-team-scenario-sharing
set +x
set -euo pipefail
: "${MAKE_PRODUCTION_HOST:?Set the approved Make zone}"
: "${MAKE_API_TOKEN:?Set a scenarios:read token for the approved zone}"
: "${MAKE_TEAM_ID:?Set the approved team ID}"
case "$MAKE_PRODUCTION_HOST" in
  eu1.make.com|eu2.make.com|us1.make.com|us2.make.com) ;;
  *) printf '%s\n' 'Use an approved Make.com production zone' >&2; exit 2 ;;
esac
[[ "$MAKE_TEAM_ID" =~ ^[1-9][0-9]{0,15}$ ]] || exit 2
MAKE_API_KEY="$MAKE_API_TOKEN" make-cli --zone "$MAKE_PRODUCTION_HOST" --output json \
  scenarios list --team-id "$MAKE_TEAM_ID" |
  jq -ces '
    if length != 1 then error("Unexpected Make CLI scenario response") else .[0] end |
    (if type == "array" then . elif type == "object" then .scenarios else null end) |
    if type == "array" and all(.[]; type == "object" and (.id | type == "number") and
        (.isShared | type == "boolean"))
    then {sampled: length, shared_scenario_ids: [.[] | select(.isShared) | .id]}
    else error("Unexpected Make CLI scenario response") end'
# HTH Guide Excerpt: end inspect-team-scenario-sharing
