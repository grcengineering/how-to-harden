#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-3.4
#   guide:   https://howtoharden.com/guides/replit/#34-cap-agent-spend-with-budgets-and-per-user-limits
#   profile: L2
#   mode:    read-only
#   requires: REPLIT_ADMIN_API_KEY(Enterprise Admin API key, read-only access)
# =============================================================================
# HTH Replit Control 3.4: Cap Agent Spend with Budgets and Per-User Limits
# Profile Level: L2 (Walk) | Plan: Enterprise (Admin API is beta, account admins only)
# Frameworks: NIST 800-53 SC-6/CM-6 | CIS Controls v8 4.1
# Sources: https://docs.replit.com/billing/managing-spend
#          https://docs.replit.com/teams/admin-api   (endpoint reference: https://api.replit.com/docs)
# Dependencies: curl, jq
#
# WHAT THIS PROVES. GET /v1/budgets (scope read:*) returns the Account spending controls
# — usageAlertThresholdUsd (notification only) and serviceShutdownLimitUsd (suspends
# usage-based services) — where "A null threshold means that control is not configured",
# plus the Agent usage limits configured for workspaces, groups and members. Findings: no
# shutdown limit, no alert threshold, or a workspace with no default per-user Agent limit.
#
# The write side exists — POST /v1/budgets with a `write:budgets` key sets or clears a
# budget — but this pack deliberately stays read-only so it can run on a read-only key.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (nothing was verified)
# =============================================================================

set -Eeuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO} — nothing was verified" >&2; exit 2' ERR

REPLIT_API_BASE="${REPLIT_API_BASE:-https://api.replit.com/v1}"
[ -n "${REPLIT_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set REPLIT_ADMIN_API_KEY (an Enterprise Admin API key, rpl_…; read-only access is enough)" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
ACC_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${ACC_FILE}"' EXIT

# One GET into BODY_FILE. Anything but a 200 carrying {data: [...], pagination: {...}} is a
# precondition (exit 2): a control is never judged on evidence that was not returned.
api_get() {
  local code rc=0
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' --max-time 60 \
    -H "Authorization: Bearer ${REPLIT_ADMIN_API_KEY}" \
    -H "Accept: application/json" \
    "${REPLIT_API_BASE}$1") || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET $1 — no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET $1 returned HTTP ${code} ($(jq -r '.error.code // "unknown"' "${BODY_FILE}" 2>/dev/null || echo unknown))" >&2
    case "${code}" in 401|403) echo "  The key is invalid or revoked, or is not an Enterprise account-admin key." >&2 ;; esac
    exit 2
  fi
  if ! jq -e '(.data | type) == "array" and (.pagination.hasMore | type) == "boolean"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET $1 — HTTP 200 without a {data, pagination} body; refusing to read it as an empty list" >&2; exit 2
  fi
}

# Follows pagination.cursor until hasMore is false; result lands in ITEMS (a JSON array).
paginate() { # paginate <path> [query]
  local query="${2:+$2&}" cursor="" pages=0
  : > "${ACC_FILE}"
  while :; do
    if [ -n "${cursor}" ]; then
      api_get "$1?${query}limit=100&cursor=$(jq -rn --arg c "${cursor}" '$c | @uri')"
    else
      api_get "$1?${query}limit=100"
    fi
    jq -c '.data[]' "${BODY_FILE}" >> "${ACC_FILE}"
    pages=$((pages + 1))
    if [ "$(jq -r '.pagination.hasMore' "${BODY_FILE}")" != "true" ]; then break; fi
    cursor=$(jq -r '.pagination.cursor' "${BODY_FILE}")
    if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: $1 did not finish paginating after 1000 pages" >&2; exit 2; fi
  done
  ITEMS=$(jq -s '.' "${ACC_FILE}")
}

# HTH Guide Excerpt: begin budgets-audit
# Account spending controls must both be set; every workspace needs a default per-user
# Agent limit.
FINDING=0
paginate "/budgets" "type=account_spending_controls"
ACCOUNT=$(printf '%s' "${ITEMS}" | jq -c '[.[] | select(.type == "account_spending_controls")]')
if [ "$(printf '%s' "${ACCOUNT}" | jq 'length')" -ne 1 ]; then
  echo "PRECONDITION: expected exactly one account_spending_controls entry from /budgets" >&2; exit 2
fi
ALERT=$(printf '%s' "${ACCOUNT}" | jq -r '.[0].usageAlertThresholdUsd // "unset"')
SHUTDOWN=$(printf '%s' "${ACCOUNT}" | jq -r '.[0].serviceShutdownLimitUsd // "unset"')
echo "Replit 3.4 — budgets and Agent usage limits"
echo "  account: usageAlertThresholdUsd=${ALERT} serviceShutdownLimitUsd=${SHUTDOWN}"
if [ "${SHUTDOWN}" = "unset" ]; then
  echo "FINDING: no service shutdown limit — usage-based services (Agent included) are never suspended."
  FINDING=1
fi
if [ "${ALERT}" = "unset" ]; then
  echo "FINDING: no usage alert threshold — nobody is told before the cap is reached."
  FINDING=1
fi

paginate "/workspaces"
WORKSPACES=$(printf '%s' "${ITEMS}" | jq -c '[.[] | {id, slug}]')
if [ "$(printf '%s' "${WORKSPACES}" | jq 'length')" -eq 0 ]; then
  echo "PRECONDITION: /workspaces returned no workspaces" >&2; exit 2
fi
paginate "/budgets" "type=workspace_default_user_limit"
UNCAPPED=$(printf '%s' "${WORKSPACES}" | jq -c --argjson limits "${ITEMS}" '
  [ .[] | select(.id as $w | any($limits[]; .workspaceId == $w) | not) | .slug ]')
echo "  workspaces: $(printf '%s' "${WORKSPACES}" | jq 'length'); with a default per-user Agent limit: $(printf '%s' "${ITEMS}" | jq 'length')"
if [ "$(printf '%s' "${UNCAPPED}" | jq 'length')" -gt 0 ]; then
  echo "FINDING: workspaces with no default per-user Agent limit: $(printf '%s' "${UNCAPPED}" | jq -r 'join(", ")')"
  FINDING=1
fi
if [ "${FINDING}" -eq 0 ]; then
  echo "COMPLIANT: account alert + shutdown thresholds set; every workspace caps per-user Agent spend."
fi
exit "${FINDING}"
# HTH Guide Excerpt: end budgets-audit
