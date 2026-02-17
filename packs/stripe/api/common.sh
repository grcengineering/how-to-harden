#!/usr/bin/env bash
# HTH Stripe Pack — Shared utilities
# All API scripts source this file for common helpers.
set -euo pipefail

# ── Required environment ──────────────────────────────────
: "${STRIPE_SECRET_KEY:?Set STRIPE_SECRET_KEY to a Stripe API secret key}"

STRIPE_BASE="https://api.stripe.com/v1"

# ── HTTP helpers ──────────────────────────────────────────
stripe_get()    { curl -sf -u "${STRIPE_SECRET_KEY}:" "${STRIPE_BASE}$1"; }
stripe_post()   { curl -sf -X POST   -u "${STRIPE_SECRET_KEY}:" -d "$2" "${STRIPE_BASE}$1"; }
stripe_delete() { curl -sf -X DELETE -u "${STRIPE_SECRET_KEY}:" "${STRIPE_BASE}$1"; }

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
