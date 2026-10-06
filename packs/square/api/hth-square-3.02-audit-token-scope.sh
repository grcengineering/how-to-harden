#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: square-3.2
#   guide:   https://howtoharden.com/guides/square/#32-configure-api-security
#   profile: L2
#   mode:    read-only
#   requires: SQUARE_ACCESS_TOKEN(the OAuth access token or personal access token under review; no scope is needed to introspect itself), SQUARE_BASE(optional; Sandbox = https://connect.squareupsandbox.com/v2), HTH_SQUARE_TOKEN_MIN_DAYS(optional, default 7), HTH_SQUARE_HTTP_TIMEOUT(optional, seconds per request, default 60)
# =============================================================================
# HTH Square Control 3.2: Configure API Security — credential introspection
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.11; NIST 800-53 SC-12
# Source: https://howtoharden.com/guides/square/#32-configure-api-security
# Dependencies: curl, jq
#
# VERIFICATION STATUS (validate-hth-guide, 2026-09-24): every endpoint, scope and
# field below was transcribed from the Square API reference (version 2026-09-16)
# and exercised offline — fixtures replaying Square's documented responses, plus a
# fail-closed run against the Sandbox host. It has NOT yet been executed against a
# live Square account.
#
# API surface: POST /oauth2/token/status (RetrieveTokenStatus) — introspects an
#   OAuth access token OR an application's personal access token. Returns scopes,
#   expires_at ("Empty if the token never expires"), client_id, merchant_id.
#
# TRAP 1: the endpoint lives at the host root (/oauth2/...), NOT under /v2.
# TRAP 2: it introspects ONLY the token it is called with. It cannot list other
#   tokens, and "review connected applications" (Step 1) has no API surface —
#   that stays ClickOps.
# TRAP 3: an empty expires_at means the token NEVER expires — the personal access
#   token shape the guide calls unrestricted. Absence is the risky value.
# TRAP 4: because absence of expires_at is itself the finding, a 200 whose body
#   introspects nothing (no scopes list and no client_id, or an errors[] array)
#   would otherwise read as "never expires". That is a precondition failure
#   (exit 2): no token was described, so nothing was judged.
# TRAP 5: expires_at is RFC 3339 — it can carry fractional seconds and a numeric
#   offset (+00:00) instead of Z, which jq's fromdateiso8601 rejects. The offset
#   is applied by hand, and a value that still cannot be read is a precondition
#   failure raised BEFORE anything is printed, never a half-printed report.
set -euo pipefail

[ -n "${SQUARE_ACCESS_TOKEN:-}" ] || { echo "PRECONDITION: SQUARE_ACCESS_TOKEN is not set (see requires: above)" >&2; exit 2; }
SQUARE_BASE="${SQUARE_BASE:-https://connect.squareup.com/v2}"
SQUARE_HOST="${SQUARE_BASE%/v2}"
SQUARE_VERSION="${SQUARE_VERSION:-2026-09-16}"
MIN_DAYS="${HTH_SQUARE_TOKEN_MIN_DAYS:-7}"
HTTP_TIMEOUT="${HTH_SQUARE_HTTP_TIMEOUT:-60}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-square.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}"' EXIT

# HTH Guide Excerpt: begin api-audit-token-status
audit() {
  local code rc expires writes findings=0 left exp_epoch
  set +e
  code=$(curl -sS --max-time "${HTTP_TIMEOUT}" -o "${BODY_FILE}" -w '%{http_code}' "${SQUARE_HOST}/oauth2/token/status" \
    -H "Authorization: Bearer ${SQUARE_ACCESS_TOKEN}" -H "Square-Version: ${SQUARE_VERSION}" \
    -H "Content-Type: application/json" --data '{}')
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then echo "PRECONDITION: /oauth2/token/status — no HTTP response (curl exit ${rc})" >&2; exit 2; fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: /oauth2/token/status returned HTTP ${code} ($(jq -r '([.errors[]? | "\(.category)/\(.code)"] | join(", ")) as $e | if $e != "" then $e else (.type // .message // "no error body") end' "${BODY_FILE}" 2>/dev/null || echo "unparseable body"))" >&2
    exit 2
  fi
  # TRAP 4: a 200 must actually describe a token before its missing expires_at means anything.
  if ! jq -e '((.errors // []) | length) == 0
              and ((.scopes | type) == "array" or ((.client_id // "") | length) > 0)' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: /oauth2/token/status returned HTTP 200 without introspection data (no scopes list or client_id, or an errors array) — no token was described (TRAP 4)." >&2
    exit 2
  fi

  expires=$(jq -r '.expires_at // ""' "${BODY_FILE}")
  if [ -n "${expires}" ]; then
    # TRAP 5: RFC 3339 by hand — fractional seconds dropped, a numeric offset applied.
    exp_epoch=$(jq -rn --arg e "${expires}" '
      [$e | capture("^(?<b>[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\\.[0-9]+)?(?<z>Z|[+-][0-9]{2}:[0-9]{2})$")] | .[0] as $m
      | (($m.b + "Z") | fromdateiso8601)
        - (if $m.z == "Z" then 0 else (($m.z[1:3] | tonumber) * 3600 + ($m.z[4:6] | tonumber) * 60) * (if $m.z[0:1] == "+" then 1 else -1 end) end)' 2>/dev/null) \
      && [ -n "${exp_epoch}" ] && [ "${exp_epoch}" != "null" ] \
      || { echo "PRECONDITION: expires_at '${expires}' is not an RFC 3339 timestamp — cannot judge expiry." >&2; exit 2; }
  fi
  writes=$(jq -r '[.scopes[]? | select(endswith("_WRITE"))] | join(" ")' "${BODY_FILE}")
  echo "Square 3.2 — introspection of the token in use (TRAP 2: this token only)"
  echo "  scopes: $(jq '.scopes | length' "${BODY_FILE}") total · write scopes: ${writes:-(none)}"
  echo "  expires_at: ${expires:-(never — TRAP 3)}"

  if [ -z "${expires}" ]; then
    echo "FINDING: this token never expires. Treat it as a full-account credential: keep it only in a secrets manager, never share it across environments, and prefer a scoped OAuth token for integrations."
    findings=$((findings + 1))
  else
    left=$(( (exp_epoch - $(date -u +%s)) / 86400 ))
    echo "  days until expiry: ${left}"
    if [ "${left}" -lt "${MIN_DAYS}" ]; then
      echo "FINDING: token expires in ${left} day(s) — refresh on a schedule shorter than 30 days instead of waiting for API failures."
      findings=$((findings + 1))
    fi
  fi
  if [ -n "${writes}" ]; then
    echo "REVIEW: the token carries write scopes (${writes}). If this integration only reads, re-authorize it with *_READ scopes only."
  fi
  [ "${findings}" -eq 0 ] && { echo "COMPLIANT: token expires and is not due for refresh within ${MIN_DAYS} days."; return 0; }
  return 1
}
# HTH Guide Excerpt: end api-audit-token-status

audit
