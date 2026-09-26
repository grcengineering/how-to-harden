#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-7.2
#   guide:   https://howtoharden.com/guides/lovable/#72-run-the-security-center-as-your-posture-dashboard
#   profile: L2
#   mode:    read-only
#   requires: LOV_PUBLIC_API_KEY(Lovable API key, "Read only" preset: Workspace Read; caller needs Security Center access), LOVABLE_WORKSPACE_ID
# =============================================================================
# HTH Lovable Control 7.2: Run the Security Center as Your Posture Dashboard
# Profile Level: L2 (Walk) | Plan: Business or Enterprise
# Frameworks: NIST 800-53 RA-5/CA-7 | CIS Controls v8 7.5, 16.13
# Interface: Lovable REST API v1 (GA 2026-09-11)
#   Get workspace security insights:
#   https://docs.lovable.dev/api-reference/security-governance/get-workspace-security-insights
# Dependencies: curl, jq
#
# The Security center's insights, as data you can schedule and keep. The endpoint
# returns workspace summary counts and every finding TYPE with its review_priority
# (needs_review | review_recommended | no_review_needed) and project_count —
# "including types with zero matches", covering public apps with security errors,
# unresolved personal data, externally shared projects and ownerless projects.
# Because zero-match types are always listed, an EMPTY findings array means the
# response did not describe the workspace, and is reported UNKNOWN, never clean.
# The Security center keeps only the latest results: keep this pack's output (or the
# console CSV export) as your posture history.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition, unknown, or unreadable response
# =============================================================================
set -euo pipefail

# Explicit guards (exit 2): a bare ${VAR:?} exits 1, which would read as a finding.
[ -n "${LOV_PUBLIC_API_KEY:-}" ]   || { echo "PRECONDITION: set LOV_PUBLIC_API_KEY — a Lovable API key (Settings -> Access tokens, Read only preset)" >&2; exit 2; }
[ -n "${LOVABLE_WORKSPACE_ID:-}" ] || { echo "PRECONDITION: set LOVABLE_WORKSPACE_ID — the workspace the key belongs to" >&2; exit 2; }
LOV_API_BASE="${LOV_API_BASE:-https://api.lovable.dev}"
LOV_VERSION="2026-09-11"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

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

WS_ID_ENC="$(printf '%s' "${LOVABLE_WORKSPACE_ID}" | jq -sRr @uri)"

# HTH Guide Excerpt: begin audit-security-insights
INSIGHTS="$(lov_get "/v1/workspaces/${WS_ID_ENC}/security-center/insights")" || exit 2

printf '%s' "${INSIGHTS}" | jq -e '
  (.findings | type) == "array" and (.findings | length) > 0
  and all(.findings[]; (.review_priority | type) == "string" and (.project_count | type) == "number")
  and (.summary.total_projects.value | type) == "number"' >/dev/null || {
  echo "ERROR 7.2: insights response is empty or malformed — workspace posture UNKNOWN" >&2; exit 2; }

printf '%s' "${INSIGHTS}" | jq -r '
  "Workspace: \(.summary.total_projects.value) projects, \(.summary.externally_published.value) public, \(.summary.workspace_members.value) members (as of \(.as_of // "unknown"))",
  "Review priority: high=\(.summary.risk.needs_review) medium=\(.summary.risk.review_recommended) low=\(.summary.risk.no_review_needed)",
  (.findings[] | "  [\(.review_priority)] \(.title): \(.project_count) project(s)")'

HIGH="$(printf '%s' "${INSIGHTS}" | jq '[.findings[] | select(.review_priority == "needs_review" and .project_count > 0)] | length')"
if [ "${HIGH}" -gt 0 ]; then
  echo "FAIL 7.2: ${HIGH} high-priority finding type(s) match at least one project — triage them in Settings -> Security -> Security center"
  exit 1
fi
echo "PASS 7.2: no high-priority (needs_review) finding type matches any project"
exit 0
# HTH Guide Excerpt: end audit-security-insights
