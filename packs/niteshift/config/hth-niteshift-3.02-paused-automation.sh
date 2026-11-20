#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: niteshift-3.2
#   guide: https://howtoharden.com/guides/niteshift/#32-start-repository-automations-paused
#   profile: L2
#   mode: read-only
#   requires: Bash; prints a paused candidate for manual review
# Source: https://docs.niteshift.dev/automations.md (available; checked 2026-11-18)
# HTH Guide Excerpt: begin paused-automation
set -euo pipefail
export LC_ALL=C
handle="${1:-}"
if [[ $# -ne 1 || ! "$handle" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ || ${#handle} -gt 63 ]]; then
  printf '%s\n' 'Supply one existing, dedicated service-account handle.' >&2
  exit 2
fi
printf '%s\n' \
  '---' \
  'schemaVersion: 1' \
  'key: weekly-review' \
  'name: Weekly review' \
  "runAs: {serviceAccount: '$handle'}" \
  'status: paused' \
  'triggers:' \
  '  - source: schedule' \
  '    eventType: rrule' \
  '    status: paused' \
  '    config: {rrule: "FREQ=WEEKLY;BYDAY=MO;BYHOUR=9;BYMINUTE=0", timezone: UTC}' \
  '---' \
  '' \
  'Summarize test status for the approved pilot repository. Do not edit files, write comments, or invoke external integrations.'
# HTH Guide Excerpt: end paused-automation
