#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: miro-3.2
#   guide:   https://howtoharden.com/guides/miro/#32-api-token-security
#   profile: L1
#   mode:    read-only
#   requires: MIRO_ACCESS_TOKEN(the access token under review — any valid Miro token; no extra scope is needed to inspect itself)
# =============================================================================
# HTH Miro Control 3.2: API Token Security
# Profile Level: L1 (Crawl)
# Frameworks: NIST 800-53 IA-5
# Source: https://howtoharden.com/guides/miro/#32-api-token-security
# Dependencies: curl, jq
#
# WHAT THIS PROVES. Asks Miro what the token in MIRO_ACCESS_TOKEN can actually
# do and fails when it carries a high-impact scope, or (when MIRO_ALLOWED_SCOPES
# is set) any scope outside the integration's declared allowlist.
#   GET /v1/oauth-token   get-access-token-context
#     -> type, scopes[], team, organization, user, createdBy
# Run it once per integration token you hold. It inspects the token it is
# given; it cannot enumerate other people's tokens.
#
# ── TRAP 1: revocation is a write and is not in this pack ────────────────────
# POST /v2/oauth/revoke (revoke-token-v2) ends a token. It is mutating, so it
# lives outside this read-only audit; revoke deliberately, token by token.
#
# ── TRAP 2: the high-impact list is Miro's, not a guess ──────────────────────
# sessions:delete, boards:export, contentlogs:export,
# organizations:cases:management and auditlogs:read are all named on
# https://developers.miro.com/docs/scopes. Each grants org-wide reach that the
# rest of the guide does not otherwise constrain (see the guide's scope table).
# Override with MIRO_HIGH_IMPACT_SCOPES (comma-separated) if Miro adds more.
#
# ── TRAP 3: an empty scope list is unreadable, not least-privilege ───────────
# A valid token always carries scopes. A response without a scopes array is a
# precondition failure, never a clean result.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${MIRO_ACCESS_TOKEN:?set MIRO_ACCESS_TOKEN — the Miro access token to inspect}"
MIRO_API_BASE="${MIRO_API_BASE:-https://api.miro.com}"
MIRO_HIGH_IMPACT_SCOPES="${MIRO_HIGH_IMPACT_SCOPES:-sessions:delete,boards:export,contentlogs:export,organizations:cases:management,auditlogs:read}"
MIRO_ALLOWED_SCOPES="${MIRO_ALLOWED_SCOPES:-}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-miro.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT
HTTP_CODE=""; BODY=""

precondition() { echo "PRECONDITION: $*" >&2; exit 2; }

# GET only — no -X flag anywhere, so check 14 sees a read-only file.
api_get() {
  local label="$1" path="$2" rc code msg
  set +e
  HTTP_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    -H "Authorization: Bearer ${MIRO_ACCESS_TOKEN}" \
    -H "Accept: application/json" \
    "${MIRO_API_BASE}${path}" 2>/dev/null)
  rc=$?
  set -e
  [ "${rc}" -eq 0 ] || HTTP_CODE="000"
  BODY=$(cat "${BODY_FILE}" 2>/dev/null || true)
  if [ "${HTTP_CODE}" = "200" ]; then
    printf '%s' "${BODY}" | jq -e . >/dev/null 2>&1 || precondition "GET ${label} returned 200 with a body that is not JSON"
    return 0
  fi
  code=$(printf '%s' "${BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown)
  msg=$(printf '%s' "${BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message")
  case "${HTTP_CODE}" in
    000)     precondition "GET ${label} — no HTTP response (network, DNS, or TLS failure)" ;;
    400|401) precondition "GET ${label} returned ${HTTP_CODE} (${code}) — Miro rejected the token as invalid" ;;
    429)     precondition "GET ${label} returned 429 — rate limited; re-run later" ;;
    *)       precondition "GET ${label} returned HTTP ${HTTP_CODE} (${code}) — ${msg}" ;;
  esac
}

# HTH Guide Excerpt: begin token-scope-audit
# Read the token's own context, then compare its scopes against the high-impact
# list and, when one is declared, against the integration's allowlist.
api_get "/v1/oauth-token" "/v1/oauth-token"
printf '%s' "${BODY}" | jq -e '.scopes | type == "array" and length > 0' >/dev/null 2>&1 \
  || precondition "token context returned no scopes array — cannot judge the token"

SCOPES=$(printf '%s' "${BODY}" | jq -r '.scopes[] | tostring' | sort -u) \
  || precondition "could not read the token's scopes"
# The comparisons run in jq, which has no "no match" exit status: an empty
# result exits 0 and any non-zero exit is an error. (grep exits 1 for no match
# and 2 for an error, so "|| true" would read a failed comparison as no finding.)
HIGH=$(printf '%s' "${BODY}" | jq -r --arg list "${MIRO_HIGH_IMPACT_SCOPES}" \
  '($list | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $l
   | [.scopes[] | tostring | select(IN($l[]))] | unique | .[]') \
  || precondition "could not compare the token's scopes against the high-impact list"
EXTRA=""
if [ -n "${MIRO_ALLOWED_SCOPES}" ]; then
  EXTRA=$(printf '%s' "${BODY}" | jq -r --arg list "${MIRO_ALLOWED_SCOPES}" \
    '($list | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $l
     | [.scopes[] | tostring | select(IN($l[]) | not)] | unique | .[]') \
    || precondition "could not compare the token's scopes against MIRO_ALLOWED_SCOPES"
fi

echo "Miro 3.2 — access-token scope review"
echo "  token type: $(printf '%s' "${BODY}" | jq -r '.type // "unknown"')"
echo "  scopes ($(printf '%s\n' "${SCOPES}" | grep -c .)): $(printf '%s' "${SCOPES}" | tr '\n' ' ')"
FINDINGS=0
if [ -n "${HIGH}" ]; then
  echo "  FINDING: high-impact scopes granted: $(printf '%s' "${HIGH}" | tr '\n' ' ')"
  FINDINGS=$((FINDINGS + 1))
fi
if [ -n "${EXTRA}" ]; then
  echo "  FINDING: scopes outside MIRO_ALLOWED_SCOPES: $(printf '%s' "${EXTRA}" | tr '\n' ' ')"
  FINDINGS=$((FINDINGS + 1))
fi
[ -n "${MIRO_ALLOWED_SCOPES}" ] || echo "  NOTE: set MIRO_ALLOWED_SCOPES to the scopes this integration needs to check least privilege"
# HTH Guide Excerpt: end token-scope-audit

[ "${FINDINGS}" -eq 0 ] || exit 1
echo "  OK"
exit 0
