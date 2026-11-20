#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: assembled-wfm-3.1
#   guide: https://howtoharden.com/guides/assembled-wfm/#31-collect-and-review-scheduling-history
#   profile: L2
#   mode: read-only
#   requires: bash, curl, python3; ASSEMBLED_API_KEY; ASSEMBLED_START_TIME; ASSEMBLED_END_TIME
# HTH Assembled WFM 3.1: Collect and Review Scheduling History
# NIST: AU-6 | Available: GET /v0/event_changes
# Source: https://docs.assembled.com/#event-changes (verified 2026-11-16)
# Requires the sibling packs/assembled/api/common.py in a full packs checkout.
# HTH Guide Excerpt: begin collect-schedule-changes
set +x
set -euo pipefail
umask 077
[[ $# == 0 ]] || { printf '%s\n' 'This pack accepts no arguments.' >&2; exit 1; }
python3 "$(dirname -- "$0")/../../assembled/api/common.py" events
# HTH Guide Excerpt: end collect-schedule-changes
