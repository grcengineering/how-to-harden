#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: square-3.3
#   guide:   https://howtoharden.com/guides/square/#33-verify-webhook-signatures
#   profile: L1
#   mode:    read-only
#   requires: SQUARE_ACCESS_TOKEN(the application's personal access token — OAuth tokens are rejected by this API; use the Sandbox access token for testing), SQUARE_BASE(optional; Sandbox = https://connect.squareupsandbox.com/v2), HTH_SQUARE_HTTP_TIMEOUT(optional, seconds per request, default 60)
# =============================================================================
# HTH Square Control 3.3: Verify Webhook Signatures — subscription inventory
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.10; NIST 800-53 SC-8, SI-7
# Source: https://howtoharden.com/guides/square/#33-verify-webhook-signatures
# Dependencies: curl, jq
#
# VERIFICATION STATUS (validate-hth-guide, 2026-09-24): every endpoint, scope and
# field below was transcribed from the Square API reference (version 2026-09-16)
# and exercised offline — fixtures replaying Square's documented responses, plus a
# fail-closed run against the Sandbox host. It has NOT yet been executed against a
# live Square account.
#
# API surface: GET /v2/webhooks/subscriptions?include_disabled=true
#   Rotation is POST /v2/webhooks/subscriptions/{id}/signature-key
#   (UpdateWebhookSubscriptionSignatureKey) — mutating, never called here.
#
# TRAP 1: "you cannot use OAuth access tokens with the Webhook Subscriptions API.
#   You must use the application's personal access token" (Square docs). An OAuth
#   token fails here as a precondition, not as "no subscriptions".
# TRAP 2: subscriptions belong to the APPLICATION that owns the token. Another
#   app's subscriptions are invisible, so run this once per application.
# TRAP 3: a subscription object can carry signature_key. Only whitelisted,
#   non-secret fields are ever printed, and the raw body is never echoed.
# TRAP 4: receiver-side verification cannot be proven from this API — this pack
#   proves transport and hygiene; the sdk pack for 3.3 is the receiver.
# TRAP 5: every Square response type carries an errors[] field, and an HTTP 200
#   can still hold one. Any errors[] entry (or a body that is not a JSON object)
#   on ANY page is a precondition failure: an empty or partial list read from a
#   failed page would otherwise pass as "no subscriptions" or "all HTTPS".
set -euo pipefail

[ -n "${SQUARE_ACCESS_TOKEN:-}" ] || { echo "PRECONDITION: SQUARE_ACCESS_TOKEN is not set (see requires: above)" >&2; exit 2; }
SQUARE_BASE="${SQUARE_BASE:-https://connect.squareup.com/v2}"
SQUARE_VERSION="${SQUARE_VERSION:-2026-09-16}"
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
    if [ "${code}" = "401" ] || [ "${code}" = "403" ]; then
      echo "  This API accepts only the application's personal access token (TRAP 1)." >&2
    fi
    exit 2
  fi
  # TRAP 5: a 200 is only evidence when it is a JSON object with no errors[] entry.
  if ! jq -e '(type == "object") and (((.errors // []) | length) == 0)' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: ${url%%\?*} returned HTTP 200 with an errors[] array or a non-JSON body ($(jq -r '([.errors[]? | "\(.category)/\(.code)"] | join(", ")) as $e | if $e != "" then $e else "no error detail" end' "${BODY_FILE}" 2>/dev/null || echo "unparseable body")) — the scan is incomplete, so no verdict is given" >&2
    exit 2
  fi
}

# HTH Guide Excerpt: begin api-audit-webhook-subscriptions
audit() {
  local cursor="" pages=0 subs total insecure disabled
  : > "${ITEMS_FILE}"
  while :; do
    sq "${SQUARE_BASE}/webhooks/subscriptions?include_disabled=true&limit=100${cursor:+&cursor=$(jq -rn --arg c "${cursor}" '$c|@uri')}"
    jq -c '.subscriptions[]? | {id, name, enabled, notification_url, api_version, event_count: ((.event_types // []) | length)}' \
      "${BODY_FILE}" >> "${ITEMS_FILE}"
    cursor=$(jq -r '.cursor // ""' "${BODY_FILE}")
    pages=$((pages + 1))
    [ -n "${cursor}" ] || break
    if [ "${pages}" -ge 500 ]; then
      echo "PRECONDITION: ListWebhookSubscriptions still returned a cursor after 500 pages — the inventory is incomplete, so no verdict is given." >&2
      exit 2
    fi
  done
  subs=$(jq -s '.' "${ITEMS_FILE}")
  total=$(j "${subs}" 'length')

  echo "Square 3.3 — webhook subscriptions for the token's application (TRAP 2)"
  echo "  subscriptions (including disabled): ${total}"
  j "${subs}" -r '.[] | "    - subscription=…\((.id // "unknown")[-6:]) enabled=\(.enabled // false) api_version=\(.api_version // "?") events=\(.event_count) url_scheme=\((.notification_url // "") | split(":")[0])"'

  if [ "${total}" -eq 0 ]; then
    echo "NO SUBSCRIPTIONS: this application receives no webhooks, so there is nothing to sign or verify."
    return 0
  fi
  insecure=$(j "${subs}" '[.[] | select(((.notification_url // "") | startswith("https://")) | not)] | length')
  disabled=$(j "${subs}" '[.[] | select((.enabled // false) | not)] | length')
  if [ "${disabled}" -gt 0 ]; then
    echo "REVIEW: ${disabled} disabled subscription(s) still hold a signature key — delete them if they are not coming back."
  fi
  if [ "${insecure}" -gt 0 ]; then
    echo "FINDING: ${insecure} subscription(s) deliver to a non-HTTPS notification URL — the signed payload travels in clear text."
    return 1
  fi
  echo "COMPLIANT: every subscription delivers over HTTPS. Verify the receiver separately (TRAP 4)."
  return 0
}
# HTH Guide Excerpt: end api-audit-webhook-subscriptions

audit
