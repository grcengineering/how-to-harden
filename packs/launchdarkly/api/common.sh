#!/usr/bin/env bash
# HTH LaunchDarkly Pack — Shared utilities
# All API scripts source this file for common helpers.
set -euo pipefail

# ── Required environment ──────────────────────────────────
: "${LD_API_KEY:?Set LD_API_KEY to a LaunchDarkly API access token}"
: "${LD_PROJECT_KEY:?Set LD_PROJECT_KEY to the LaunchDarkly project key}"

LD_BASE="https://app.launchdarkly.com/api/v2"
LD_API_VERSION="20240415"

# ── HTTP helpers ──────────────────────────────────────────
ld_get()    { curl -sf -H "Authorization: ${LD_API_KEY}" -H "LD-API-Version: ${LD_API_VERSION}" "${LD_BASE}$1"; }
ld_post()   { curl -sf -X POST   -H "Authorization: ${LD_API_KEY}" -H "LD-API-Version: ${LD_API_VERSION}" -H "Content-Type: application/json" -d "$2" "${LD_BASE}$1"; }
ld_patch()  { curl -sf -X PATCH  -H "Authorization: ${LD_API_KEY}" -H "LD-API-Version: ${LD_API_VERSION}" -H "Content-Type: application/json" -d "$2" "${LD_BASE}$1"; }
ld_put()    { curl -sf -X PUT    -H "Authorization: ${LD_API_KEY}" -H "LD-API-Version: ${LD_API_VERSION}" -H "Content-Type: application/json" -d "$2" "${LD_BASE}$1"; }
ld_delete() { curl -sf -X DELETE -H "Authorization: ${LD_API_KEY}" -H "LD-API-Version: ${LD_API_VERSION}" "${LD_BASE}$1"; }

# Semantic PATCH (LaunchDarkly uses semantic patches for many resources)
ld_semantic_patch() {
  curl -sf -X PATCH \
    -H "Authorization: ${LD_API_KEY}" \
    -H "LD-API-Version: ${LD_API_VERSION}" \
    -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
    -d "$2" "${LD_BASE}$1"
}

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
banner() { printf '\n\033[1;36m══ HTH LaunchDarkly %s ══\033[0m\n' "$*"; }

# ── Summary counters ─────────────────────────────────────
_applied=0 _failed=0 _skipped=0
increment_applied() { ((_applied++)) || true; }
increment_failed()  { ((_failed++))  || true; }
increment_skipped() { ((_skipped++)) || true; }
summary() { printf '\n  Applied: %d  Failed: %d  Skipped: %d\n' "$_applied" "$_failed" "$_skipped"; }
