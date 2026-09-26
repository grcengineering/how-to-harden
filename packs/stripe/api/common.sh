#!/usr/bin/env bash
# HTH Stripe Pack — Shared utilities
# All API scripts source this file for common helpers.
set -euo pipefail

# ── Required environment ──────────────────────────────────
# Any Stripe API key that Basic-auths against api.stripe.com works here. Prefer a
# restricted key (rk_…) scoped to exactly the resources the pack reads; each pack
# header's `requires:` line names the permissions it needs.
: "${STRIPE_SECRET_KEY:?Set STRIPE_SECRET_KEY to a Stripe API key (a restricted key is recommended)}"

STRIPE_BASE="https://api.stripe.com/v1"

# ── HTTP helpers ──────────────────────────────────────────
# The key reaches curl through a config file on a process-substitution descriptor,
# never as a command-line argument, so it does not appear in the process list.
# printf is a shell builtin, so the key is not an argv value there either.
# (Process substitution rather than a here-string: a here-string needs a temp file
# and fails silently where one cannot be created.)
stripe_auth()   { printf 'user = "%s:"\n' "${STRIPE_SECRET_KEY}"; }
stripe_get()    { curl -sf -K <(stripe_auth) "${STRIPE_BASE}$1"; }
# Prints only the HTTP status code of a GET (000 when the request never completed).
stripe_status() { curl -s -o /dev/null -w '%{http_code}' -K <(stripe_auth) "${STRIPE_BASE}$1" || true; }

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
banner() { printf '\n\033[1;36m══ HTH Stripe %s ══\033[0m\n' "$*"; }

# ── Summary counters ─────────────────────────────────────
_applied=0 _failed=0 _skipped=0
increment_applied() { ((_applied++)) || true; }
increment_failed()  { ((_failed++))  || true; }
increment_skipped() { ((_skipped++)) || true; }
summary() { printf '\n  Applied: %d  Failed: %d  Skipped: %d\n' "$_applied" "$_failed" "$_skipped"; }
# Print the summary and exit non-zero when any check failed, so a caller (CI, a
# wrapper, `&&`) never reads a failed audit as success.
finish() { summary; if [ "${_failed}" -gt 0 ]; then exit 1; fi; exit 0; }
