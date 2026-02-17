#!/usr/bin/env bash
# HTH JumpCloud Pack — Shared utilities
# All API scripts source this file for common helpers.
set -euo pipefail

# ── Required environment ──────────────────────────────────
: "${JUMPCLOUD_API_KEY:?Set JUMPCLOUD_API_KEY to a JumpCloud admin API key}"

JC_V1="https://console.jumpcloud.com/api"
JC_V2="https://console.jumpcloud.com/api/v2"
JC_DI="https://api.jumpcloud.com/insights/directory/v1"

# Optional: multi-tenant org ID
JC_ORG_HEADER=""
if [ -n "${JUMPCLOUD_ORG_ID:-}" ]; then
  JC_ORG_HEADER="-H x-org-id:${JUMPCLOUD_ORG_ID}"
fi

# ── HTTP helpers ──────────────────────────────────────────
jc_get_v1()  { curl -sf -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} "${JC_V1}$1"; }
jc_put_v1()  { curl -sf -X PUT  -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} -d "$2" "${JC_V1}$1"; }
jc_post_v1() { curl -sf -X POST -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} -d "$2" "${JC_V1}$1"; }

jc_get_v2()    { curl -sf -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} "${JC_V2}$1"; }
jc_post_v2()   { curl -sf -X POST   -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} -d "$2" "${JC_V2}$1"; }
jc_put_v2()    { curl -sf -X PUT    -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} -d "$2" "${JC_V2}$1"; }
jc_delete_v2() { curl -sf -X DELETE -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} "${JC_V2}$1"; }

jc_insights()  { curl -sf -X POST -H "x-api-key:${JUMPCLOUD_API_KEY}" -H "Content-Type:application/json" ${JC_ORG_HEADER} -d "$2" "${JC_DI}$1"; }

# ── Profile-level gate ────────────────────────────────────
HTH_PROFILE="${HTH_PROFILE:-1}"
should_apply() {
  local required="${1:?}"
  [ "${HTH_PROFILE}" -ge "${required}" ]
}

# ── Logging helpers ───────────────────────────────────────
info() { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
pass() { printf '\033[0;32m[PASS]\033[0m  %s\n' "$*"; }
fail() { printf '\033[0;31m[FAIL]\033[0m  %s\n' "$*"; }
warn() { printf '\033[0;33m[WARN]\033[0m  %s\n' "$*"; }
banner() { printf '\n\033[1;36m══ HTH JumpCloud %s ══\033[0m\n' "$*"; }

# ── Summary counters ─────────────────────────────────────
_applied=0 _failed=0 _skipped=0
increment_applied() { ((_applied++)) || true; }
increment_failed()  { ((_failed++))  || true; }
increment_skipped() { ((_skipped++)) || true; }
summary() { printf '\n  Applied: %d  Failed: %d  Skipped: %d\n' "$_applied" "$_failed" "$_skipped"; }
