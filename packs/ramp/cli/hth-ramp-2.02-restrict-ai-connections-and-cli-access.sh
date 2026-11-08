#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ramp-2.2
#   guide: https://howtoharden.com/guides/ramp/#22-restrict-ai-connections-and-cli-access
#   profile: L2
#   mode: read-only
#   requires: official Ramp CLI; existing signed-in session
# HTH Ramp 2.2: Restrict AI Connections and CLI Access
# Profile: L2 | NIST: AC-6 | CIS: 6.8
# Source: https://docs.ramp.com/developer-api/v1/cli (2026-11-08)
# HTH Guide Excerpt: begin inspect-cli-identity
set +x
set -euo pipefail
umask 077
[[ $# == 0 ]] || { echo 'No arguments accepted.' >&2; exit 1; }
command -v ramp >/dev/null || { echo 'Install the official Ramp CLI first.' >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
# Never enroll, install or change tenant settings. Existing sessions may auto-refresh.
# Official CLI commit a29141b5293c4e1ad15befc9587314b52c1b0bc6:
# auth.status emits authenticated/base_url/scopes/access, not credential values.
# GetSimplifiedUserDetailRequestBody requires rationale. Explicit production target.
ramp auth status --env production --no-input --output json > "$tmp/status" 2>/dev/null || {
  echo 'Cannot read CLI sign-in state; no report emitted.' >&2; exit 1;
}
ramp users me --env production --no-input --output json \
  --rationale "Review authenticated identity for the HTH CLI access assessment" > "$tmp/me" 2>/dev/null || {
  echo 'Cannot read CLI identity; no report emitted.' >&2; exit 1;
}
# CLI output is for manual review; not interpreted as proof of least privilege.
cat "$tmp/status" "$tmp/me"
# HTH Guide Excerpt: end inspect-cli-identity
