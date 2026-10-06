#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: square-3.1
#   guide:   https://howtoharden.com/guides/square/#31-configure-device-management
#   profile: L2
#   mode:    read-only
#   requires: SQUARE_ACCESS_TOKEN(OAuth access token with DEVICES_READ; a Sandbox access token for testing), SQUARE_BASE(optional; Sandbox = https://connect.squareupsandbox.com/v2), HTH_SQUARE_DEVICE_STALE_DAYS(optional, default 90), HTH_SQUARE_HTTP_TIMEOUT(optional, seconds per request, default 60)
# =============================================================================
# HTH Square Control 3.1: Configure Device Management — Step 1 (inventory)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 1.1; NIST 800-53 CM-8
# Source: https://howtoharden.com/guides/square/#31-configure-device-management
# Dependencies: curl, jq
#
# VERIFICATION STATUS (validate-hth-guide, 2026-09-24): every endpoint, scope and
# field below was transcribed from the Square API reference (version 2026-09-16)
# and exercised offline — fixtures replaying Square's documented responses, plus a
# fail-closed run against the Sandbox host. It has NOT yet been executed against a
# live Square account.
#
# API surface: GET /v2/devices (DEVICES_READ), marked Beta in the reference.
#
# TRAP 1 — COVERAGE: the reference states "Currently, only Terminal API devices
#   are supported." Square Register, Square Stand, iPads running Square POS and
#   other hardware do NOT appear here. This pack inventories Terminal API devices
#   only; an empty result means "no Terminal API devices", never "no devices".
# TRAP 2: Step 2 of the control (device passcodes, automatic logout) has no API
#   surface — Square's Team API guide lists "set a passcode" among operations
#   Square APIs cannot perform. Those settings stay ClickOps.
# TRAP 3: device health is status.category (DeviceStatusCategory: AVAILABLE,
#   NEEDS_ATTENTION, OFFLINE), NOT attributes.updated_at. The reference defines
#   updated_at as "the most recent update to the device information. (Could
#   represent any field update on the device.)" — a device can be OFFLINE with
#   info changed yesterday, or AVAILABLE with info unchanged for a year. So:
#   any category other than AVAILABLE (including a missing one) is the FINDING;
#   stale device information is a REVIEW line that never changes the exit code.
# TRAP 4: attributes.updated_at is RFC 3339 — it can carry nanoseconds, and a
#   numeric offset (+00:00, -05:00) instead of Z. jq's fromdateiso8601 accepts
#   neither, so the timestamp is split and the offset applied by hand. A missing
#   or unreadable value counts toward the REVIEW line (freshness unconfirmed); it
#   never stops the report half-printed.
# TRAP 5: every Square response type carries an errors[] field, and an HTTP 200
#   can still hold one. Any errors[] entry (or a body that is not a JSON object)
#   on ANY page is a precondition failure: an empty or partial device list read
#   from a failed page would otherwise pass as "no devices" or "all AVAILABLE".
set -euo pipefail

[ -n "${SQUARE_ACCESS_TOKEN:-}" ] || { echo "PRECONDITION: SQUARE_ACCESS_TOKEN is not set (see requires: above)" >&2; exit 2; }
SQUARE_BASE="${SQUARE_BASE:-https://connect.squareup.com/v2}"
SQUARE_VERSION="${SQUARE_VERSION:-2026-09-16}"
STALE_DAYS="${HTH_SQUARE_DEVICE_STALE_DAYS:-90}"
HTTP_TIMEOUT="${HTH_SQUARE_HTTP_TIMEOUT:-60}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-square.XXXXXX")"   || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-square-i.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT

# j <json> <jq-args...> — pipe, not a here-string: a here-string needs a temp file
# and fails when none can be created, which must never read as a clean result.
j() { local in="$1"; shift; printf "%s" "${in}" | jq "$@"; }

# sq <url> — transport failure (including a request that outlives HTTP_TIMEOUT),
# any non-200, or a 200 carrying errors[] exits 2: evidence never returned
# cannot be a finding.
sq() {
  local url="$1" code rc
  set +e
  code=$(curl -sS --max-time "${HTTP_TIMEOUT}" -o "${BODY_FILE}" -w '%{http_code}' "${url}" \
    -H "Authorization: Bearer ${SQUARE_ACCESS_TOKEN}" -H "Square-Version: ${SQUARE_VERSION}")
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: ${url%%\?*} — no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: ${url%%\?*} returned HTTP ${code} ($(jq -r '([.errors[]? | "\(.category)/\(.code)"] | join(", ")) as $e | if $e != "" then $e else (.type // .message // "no error body") end' "${BODY_FILE}" 2>/dev/null || echo "unparseable body"))" >&2
    exit 2
  fi
  # TRAP 5: a 200 is only evidence when it is a JSON object with no errors[] entry.
  if ! jq -e '(type == "object") and (((.errors // []) | length) == 0)' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: ${url%%\?*} returned HTTP 200 with an errors[] array or a non-JSON body ($(jq -r '([.errors[]? | "\(.category)/\(.code)"] | join(", ")) as $e | if $e != "" then $e else "no error detail" end' "${BODY_FILE}" 2>/dev/null || echo "unparseable body")) — the scan is incomplete, so no verdict is given" >&2
    exit 2
  fi
}

# HTH Guide Excerpt: begin api-audit-terminal-devices
audit() {
  local cursor="" pages=0 devices total unhealthy stale now
  : > "${ITEMS_FILE}"
  while :; do
    sq "${SQUARE_BASE}/devices?limit=100${cursor:+&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')}"
    jq -c '.devices[]?' "${BODY_FILE}" >> "${ITEMS_FILE}"
    cursor=$(jq -r '.cursor // ""' "${BODY_FILE}")
    pages=$((pages + 1))
    [ -n "${cursor}" ] || break
    if [ "${pages}" -ge 500 ]; then
      echo "PRECONDITION: ListDevices still returned a cursor after 500 pages — the inventory is incomplete, so no verdict is given." >&2
      exit 2
    fi
  done
  devices=$(jq -s '.' "${ITEMS_FILE}")
  total=$(j "${devices}" 'length')
  now=$(date -u +%s)

  echo "Square 3.1 — Terminal API device inventory (TRAP 1: other hardware is not listed)"
  echo "  Terminal API devices returned: ${total}"
  j "${devices}" -r '.[] | "    - device=…\((.id // "unknown")[-6:]) type=\(.attributes.type // "?") model=\(.attributes.model // "?") version=\(.attributes.version // "?") status=\(.status.category // "UNKNOWN") info_updated_at=\(.attributes.updated_at // "(never)")"'

  if [ "${total}" -eq 0 ]; then
    echo "NO TERMINAL API DEVICES: nothing to inventory through the API. Review all other hardware in the Dashboard (TRAP 1)."
    return 0
  fi

  # TRAP 3: a missing category counts as not AVAILABLE — an unreadable status is never healthy.
  unhealthy=$(j "${devices}" '[.[] | select((.status.category // "UNKNOWN") != "AVAILABLE")] | length')
  # TRAP 4: RFC 3339 by hand — fractional seconds dropped, a numeric offset applied;
  # anything unreadable is null, and null counts for review.
  stale=$(j "${devices}" --argjson now "${now}" --argjson days "${STALE_DAYS}" '
    def epoch:
      if type != "string" then null else
        [capture("^(?<b>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\\.[0-9]+)?(?<z>Z|[+-][0-9]{2}:[0-9]{2})$")]
        | if length == 0 then null else .[0] as $m
          | (try (($m.b + "Z") | fromdateiso8601) catch null) as $t
          | if $t == null then null
            elif $m.z == "Z" then $t
            else $t - (($m.z[1:3] | tonumber) * 3600 + ($m.z[4:6] | tonumber) * 60) * (if $m.z[0:1] == "+" then 1 else -1 end)
            end
          end
      end;
    [.[] | (.attributes.updated_at | epoch) as $t
         | select($t == null or ($now - $t) > ($days * 86400))]
    | length')
  if [ "${stale}" -gt 0 ]; then
    echo "REVIEW: ${stale} Terminal API device(s) have device information not updated in ${STALE_DAYS} days, or no readable updated_at (updated_at records any change to device information, not device activity — TRAP 3)."
  fi
  if [ "${unhealthy}" -gt 0 ]; then
    echo "FINDING: ${unhealthy} Terminal API device(s) report a status other than AVAILABLE (OFFLINE, NEEDS_ATTENTION or missing) — confirm each is still in service and physically accounted for, or unpair it."
    return 1
  fi
  echo "COMPLIANT: all ${total} Terminal API device(s) report status AVAILABLE."
  return 0
}
# HTH Guide Excerpt: end api-audit-terminal-devices

audit
