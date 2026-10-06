#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-1.2
#   guide:   https://howtoharden.com/guides/lovable/#12-enforce-sso-with-short-sessions
#   profile: L1
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read), LOVABLE_WORKSPACE_ID
# =============================================================================
# HTH Lovable Control 1.2: Enforce SSO with Short Sessions
# Profile Level: L1 (Crawl) | Plan: Business or Enterprise (the public API is Business+)
# Frameworks: NIST 800-53 IA-2/IA-8/AC-12 | CIS Controls v8 6.7, 12.5
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   Get workspace: https://docs.lovable.dev/api-reference/workspaces/get-workspace
#   API basics:    https://docs.lovable.dev/api-reference/introduction
# Dependencies: curl, jq
#
# What this proves, and what it cannot. `GET /v1/workspaces/{workspace_id}` returns
# the boolean `enforce_sso` ("Whether workspace members are required to sign in
# through single sign-on"). That is the only half of 1.2 the API exposes. The IdP
# protocol, group-to-role mappings, JIT default role and the session duration
# (8h/24h/48h/7d) are console-only: Settings -> Access -> Identity.
#
# Credential. Settings -> Access tokens -> New API key -> Access "Read only",
# with a short expiry. Keys are workspace-scoped and start with `lov_`. The key
# travels in the `Lovable-API-Key` header, never in a URL. Do not store it as a
# project secret named LOVABLE_API_KEY: that name is reserved by Lovable.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition or unreadable response
# =============================================================================
set -euo pipefail

# Explicit guards (exit 2): a bare ${VAR:?} exits 1, which would read as a finding.
[ -n "${LOV_PUBLIC_API_KEY:-}" ]   || { echo "PRECONDITION: set LOV_PUBLIC_API_KEY — a Lovable API key (Settings -> Access tokens, Read only preset)" >&2; exit 2; }
[ -n "${LOVABLE_WORKSPACE_ID:-}" ] || { echo "PRECONDITION: set LOVABLE_WORKSPACE_ID — the workspace the key belongs to" >&2; exit 2; }
LOV_API_BASE="${LOV_API_BASE:-https://api.lovable.dev}"
LOV_VERSION="2026-09-11"   # pin the stable API version (first GA version)

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# GET one resource. Prints the body on HTTP 200; anything else is an error (return 2),
# reported with the API's stable error `type` (unauthorized, insufficient_scope,
# payment_required, not_found, ...). No temp files: body and status travel together.
lov_get() {
  local resp code
  resp="$(curl -sS "${LOV_API_BASE}$1" \
    -H "Lovable-API-Key: ${LOV_PUBLIC_API_KEY}" \
    -H "Lovable-Version: ${LOV_VERSION}" \
    -H "Accept: application/json" \
    -w $'\n%{http_code}')" || { echo "ERROR: GET $1 failed before an HTTP status (network/TLS)" >&2; return 2; }
  code="${resp##*$'\n'}"
  resp="${resp%$'\n'*}"
  if [ "${code}" != "200" ]; then
    echo "ERROR: GET $1 -> HTTP ${code} ($(printf '%s' "${resp}" | jq -r '.type? // "no error type"' 2>/dev/null || echo "non-JSON body"))" >&2
    return 2
  fi
  printf '%s' "${resp}"
}

# HTH Guide Excerpt: begin audit-enforce-sso
# Read the workspace and assert Enforce SSO is on. A missing or non-boolean field is
# an unreadable response (exit 2), never a pass.
WS_PATH="/v1/workspaces/$(printf '%s' "${LOVABLE_WORKSPACE_ID}" | jq -sRr @uri)"
WS="$(lov_get "${WS_PATH}")" || exit 2

# (jq -r, not -e: -e would turn a legitimate `false` into a non-zero exit.)
ENFORCE_SSO="$(printf '%s' "${WS}" | jq -r 'if (.enforce_sso | type) == "boolean" then .enforce_sso else error("enforce_sso missing") end')" || {
  echo "ERROR 1.2: workspace response carries no boolean enforce_sso; SSO state UNKNOWN" >&2
  exit 2
}
PLAN="$(printf '%s' "${WS}" | jq -r '.plan // "unknown"')"

if [ "${ENFORCE_SSO}" = "true" ]; then
  echo "PASS 1.2: Enforce SSO is on (plan: ${PLAN}). Session duration is console-only: review it at Settings -> Access -> Identity."
  exit 0
fi
echo "FAIL 1.2: Enforce SSO is off (plan: ${PLAN}). Members can sign in without your IdP; enable it at Settings -> Access -> Identity."
exit 1
# HTH Guide Excerpt: end audit-enforce-sso
