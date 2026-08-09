#!/usr/bin/env bash
# HTH 1Password Control 4.1: Enable Audit Logging
# Profile: L1 | CIS Controls: 8.2 | NIST 800-53: AU-2
# https://howtoharden.com/guides/1password/#41-enable-audit-logging
#
# Pulls all three Events API event classes (audit events, item usages,
# sign-in attempts) for SIEM forwarding, with cursor persistence between runs.
# Requires: an Events API bearer token issued in the 1Password admin console
# (Integrations -> your SIEM -> Issue Token), curl, jq.
# Verified against: https://www.1password.dev/events-api/reference/
#                   https://www.1password.dev/events-api/servers/
set -euo pipefail

command -v curl >/dev/null || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }

# HTH Guide Excerpt: begin api-events-collection
# Base URL depends on the region hosting your account:
#   US:              https://events.1password.com
#   US (Enterprise): https://events.ent.1password.com
#   Canada:          https://events.1password.ca
#   Europe:          https://events.1password.eu
OP_EVENTS_BASE="${OP_EVENTS_BASE:-https://events.1password.com}"
: "${OP_EVENTS_TOKEN:?Set OP_EVENTS_TOKEN to your Events API bearer token}"

STATE_DIR="${OP_EVENTS_STATE_DIR:-./.op-events-state}"
OUT_DIR="${OP_EVENTS_OUT_DIR:-./op-events}"
START_TIME="${OP_EVENTS_START_TIME:-$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)}"
mkdir -p "${STATE_DIR}" "${OUT_DIR}"

# Confirm which event classes this token is authorized for before pulling.
echo "== Token features =="
curl -sf -H "Authorization: Bearer ${OP_EVENTS_TOKEN}" \
  "${OP_EVENTS_BASE}/api/v2/auth/introspect" | jq '.features'

# Collect every class the guide requires: each answers a different question
# (auditevents = admin/policy tampering, itemusages = mass credential
# access, signinattempts = credential stuffing and spraying).
for FEATURE in auditevents itemusages signinattempts; do
  CURSOR_FILE="${STATE_DIR}/${FEATURE}.cursor"
  OUT_FILE="${OUT_DIR}/${FEATURE}-$(date -u +%Y%m%dT%H%M%SZ).json"

  # First request uses limit + start_time; later requests resume from the
  # stored cursor (cursor-based pagination per the API reference).
  if [ -s "${CURSOR_FILE}" ]; then
    BODY=$(jq -n --arg c "$(cat "${CURSOR_FILE}")" '{cursor: $c}')
  else
    BODY=$(jq -n --arg t "${START_TIME}" '{limit: 100, start_time: $t}')
  fi

  HAS_MORE="true"
  while [ "${HAS_MORE}" = "true" ]; do
    RESP=$(curl -sf -X POST \
      -H "Authorization: Bearer ${OP_EVENTS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${BODY}" \
      "${OP_EVENTS_BASE}/api/v2/${FEATURE}")

    # Append this page's events; persist the cursor for the next run.
    echo "${RESP}" | jq -c '.items[]' >> "${OUT_FILE}"
    CURSOR=$(echo "${RESP}" | jq -r '.cursor')
    HAS_MORE=$(echo "${RESP}" | jq -r '.has_more')
    printf '%s' "${CURSOR}" > "${CURSOR_FILE}"
    BODY=$(jq -n --arg c "${CURSOR}" '{cursor: $c}')
  done

  echo "Collected ${FEATURE} -> ${OUT_FILE} ($(wc -l < "${OUT_FILE}") events)"
done
# HTH Guide Excerpt: end api-events-collection
