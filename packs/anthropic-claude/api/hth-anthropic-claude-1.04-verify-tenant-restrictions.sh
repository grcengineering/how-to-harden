#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-claude-1.4
#   guide:   https://howtoharden.com/guides/anthropic-claude/#14-enforce-tenant-restrictions-at-the-network-edge
#   profile: L2
#   mode:    read-only
#   requires: HTH_TR_BLOCKED_KEY(API key of an org NOT on the allowlist), HTH_TR_ALLOWED_KEY(optional; key of an allowlisted org)
# =============================================================================
# HTH Anthropic Claude Control 1.4: Enforce Tenant Restrictions at the Network Edge
# Profile: L2 | NIST: SC-7, AC-4 | SOC 2: CC6.7
# Source: support.claude.com/en/articles/13198485 (Tenant Restrictions: header
#         format, "Test your configuration" request, documented error responses)
#
# Anthropic has no API that SETS tenant restrictions: your egress proxy injects
# the `anthropic-allowed-org-ids` header. What the vendor does document is how
# enforcement ANSWERS, and that is what this pack checks. Run it from inside the
# managed network, so the request crosses the proxy exactly as a user's would.
#   - key from a non-allowlisted org -> HTTP 403, error_code tenant_restriction_violation
#   - proxy header mistakes          -> HTTP 400 ("Multiple ..." / "Malformed ..." anthropic-allowed-org-ids headers)
# It prints status codes and error codes only, never a response body.
# Exit codes: 0 enforcement verified | 1 not enforced or proxy misconfigured | 2 precondition
set -euo pipefail

ANTHROPIC_API_BASE="${ANTHROPIC_API_BASE:-https://api.anthropic.com}"
HTH_TR_MODEL="${HTH_TR_MODEL:-claude-sonnet-4-6}"
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
[[ -n "${HTH_TR_BLOCKED_KEY:-}" ]] || {
  echo "PRECONDITION: set HTH_TR_BLOCKED_KEY to an API key from an organization that is NOT on the allowlist" >&2
  exit 2
}

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-anthropic-tr.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# HTH Guide Excerpt: begin api-verify-tenant-restrictions
# Send the vendor's documented test request with a given key; the key reaches
# curl as a header file, never as an argument. Sets TR_CODE and TR_ERROR.
tr_probe() {
  local key="$1"
  TR_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' "${ANTHROPIC_API_BASE}/v1/messages" \
    -H @<(printf 'x-api-key: %s\n' "${key}") \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -cn --arg m "${HTH_TR_MODEL}" '{model: $m, max_tokens: 1, messages: [{role: "user", content: "Hello"}]}')" \
    2>/dev/null) || TR_CODE="000"
  TR_ERROR=$(jq -r '.error.error_code // .error.message // "none"' "${BODY_FILE}" 2>/dev/null || echo "unparseable")
  [[ -n "${TR_ERROR}" ]] || TR_ERROR="no response body"
}

# 1. A key from an org that is NOT allowlisted must be refused by tenant restriction.
tr_probe "${HTH_TR_BLOCKED_KEY}"
if [[ "${TR_CODE}" == "403" && "${TR_ERROR}" == "tenant_restriction_violation" ]]; then
  echo "[PASS] 1.4 non-allowlisted org refused: HTTP 403 tenant_restriction_violation"
elif [[ "${TR_CODE}" == "400" && "${TR_ERROR}" == *anthropic-allowed-org-ids* ]]; then
  echo "[FAIL] 1.4 proxy header misconfigured: HTTP 400 (${TR_ERROR})"; exit 1
elif [[ "${TR_CODE}" =~ ^2 ]]; then
  echo "[FAIL] 1.4 NOT ENFORCED: a non-allowlisted org's key was served (HTTP ${TR_CODE})"; exit 1
else
  echo "PRECONDITION: inconclusive — HTTP ${TR_CODE} (${TR_ERROR}); check the key and that this host routes through the proxy" >&2
  exit 2
fi

# 2. Optional: a key from an allowlisted org must still get through.
if [[ -n "${HTH_TR_ALLOWED_KEY:-}" ]]; then
  tr_probe "${HTH_TR_ALLOWED_KEY}"
  if [[ "${TR_CODE}" =~ ^2 ]]; then
    echo "[PASS] 1.4 allowlisted org still served (HTTP ${TR_CODE})"
  else
    echo "[FAIL] 1.4 allowlisted org refused: HTTP ${TR_CODE} (${TR_ERROR})"; exit 1
  fi
fi
# HTH Guide Excerpt: end api-verify-tenant-restrictions
