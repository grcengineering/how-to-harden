#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-4.3
#   guide:   https://howtoharden.com/guides/replit/#43-govern-external-access-tokens-the-private-app-bypass-credential
#   profile: L2
#   mode:    read-only
#   requires: nothing for `scan` (default); REPLIT_EXTERNAL_TOKEN(external access token, Development environment, shortest expiry) + REPLIT_APP_URL for `probe`
# =============================================================================
# HTH Replit Control 4.3: Govern External Access Tokens (the private-app bypass credential)
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 IA-5/AC-6 | CIS Controls v8 6.1/16.9
# Availability: any deployment published with private access; no Workspace opt-in.
#   In an Enterprise Workspace only Workspace admins can manage tokens.
# Source: https://docs.replit.com/features/deployment-customization/external-access-tokens
# Dependencies: git (scan), curl (probe)
#
# Tokens are CREATED in the console only: Publishing tool -> Adjust settings ->
# Security -> External access tokens -> Create access token. Neither the docs nor
# the Admin API (https://api.replit.com/docs) expose token issuance, listing or
# revocation, so this pack covers what code CAN prove: that no repository carries
# the query-parameter form or an inline Bearer literal (`scan`), and that the
# header form actually reaches a private app (`probe`).
#
# Usage:  hth-replit-4.03-external-access-tokens.sh [scan|probe]
#   scan   (default) CI hygiene gate over the tracked files of the current git
#          work tree. Needs no credential, so it can run in every pipeline.
#   probe  one GET to ${REPLIT_APP_URL}${REPLIT_HEALTH_PATH:-/health} with the
#          token in an Authorization: Bearer header.
# Exit codes: 0 compliant | 1 finding | 2 precondition (nothing was verified)
# =============================================================================

set -euo pipefail

MODE="${1:-scan}"

# HTH Guide Excerpt: begin token-ci-hygiene-scan
# CI hygiene gate: fail the build if any tracked file uses the query-parameter token
# form or hardcodes a Bearer literal. It refuses to report "clean" when it could not
# scan: outside a git work tree `git grep` exits 128, which an `if` would silently
# read as "no match". It reports locations (path:line) only: printing the matched line
# would copy the credential into the CI log, which more people can usually read than the
# repository. The body runs in a subshell so pipefail stays local to it.
token_scan() (
  set -o pipefail   # the pipe below must report git grep's status, not sed's
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR 4.3: not inside a git work tree — nothing was scanned" >&2
    return 2
  fi
  local fail=0 rc label pattern
  for label in query-parameter bearer-literal; do
    case "${label}" in
      query-parameter) pattern='project-protection-bypass=' ;;
      # Replit external tokens are opaque; catch obvious inline Bearer literals.
      bearer-literal)  pattern='Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._-]{20,}' ;;
    esac
    rc=0
    git grep -nE "${pattern}" -- . | cut -d: -f1,2 | sed 's/^/  /' || rc=$?
    if [ "${rc}" -gt 1 ]; then
      echo "ERROR 4.3: git grep failed (rc=${rc}) — the ${label} check did not run" >&2
      return 2
    fi
    if [ "${rc}" -eq 0 ]; then
      echo "FAIL 4.3: ${label} token form at the location(s) above (line content withheld) — rotate that credential, keep it in a secret manager, and send it as an Authorization: Bearer header"
      fail=1
    fi
  done
  if [ "${fail}" -eq 0 ]; then
    echo "PASS 4.3: no query-parameter tokens or inline Bearer literals in tracked files."
  fi
  return "${fail}"
)
# HTH Guide Excerpt: end token-ci-hygiene-scan

# HTH Guide Excerpt: begin token-bearer-usage
# CORRECT usage: send the token as an Authorization: Bearer header. The docs also
# accept ?project-protection-bypass=<token>, but a credential in a URL leaks to
# server logs, proxy logs, shell history and Referer headers — use the header form.
token_probe() {
  if [ -z "${REPLIT_EXTERNAL_TOKEN:-}" ] || [ -z "${REPLIT_APP_URL:-}" ]; then
    echo "ERROR 4.3: set REPLIT_EXTERNAL_TOKEN (from a secret manager — never inline it) and REPLIT_APP_URL (e.g. https://myapp.replit.app)" >&2
    return 2
  fi
  local path="${REPLIT_HEALTH_PATH:-/health}" code rc=0
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 \
    -H "Authorization: Bearer ${REPLIT_EXTERNAL_TOKEN}" \
    "${REPLIT_APP_URL}${path}") || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "ERROR 4.3: no HTTP response from ${REPLIT_APP_URL} (curl exit ${rc})" >&2
    return 2
  fi
  case "${code}" in
    2??) echo "PASS 4.3: bearer-header token reached ${path} (HTTP ${code})"; return 0 ;;
    3??) echo "FAIL 4.3: HTTP ${code} — redirected (usually to sign-in): the token was not accepted for this environment"; return 1 ;;
    401|403) echo "FAIL 4.3: HTTP ${code} — token rejected (expired, revoked, or minted for the other environment)"; return 1 ;;
    *) echo "ERROR 4.3: HTTP ${code} from ${path} — the app answered but the probe path is wrong; set REPLIT_HEALTH_PATH" >&2; return 2 ;;
  esac
}
# HTH Guide Excerpt: end token-bearer-usage

# HTH Guide Excerpt: begin token-rotation-notes
# Operational rules transcribed from the docs (2026-09-24) — encode them in your runbook:
#   * One token = one environment: Development (*.replit.dev) OR Production
#     (*.replit.app + custom domains).
#   * PRODUCTION TOKENS SURVIVE REPUBLISH (including a new version). Replit revokes them
#     when you unpublish the deployment, delete it, or switch the Project from private
#     to public.
#   * Expiry choices: 1 hour, 24 hours, 7 days, 30 days, 3 months, 1 year, 5 years.
#     There is no permanent option; prefer <= 30 days for CI. Do not pick 5 years.
#   * Revocation is immediate and irreversible, and you can only revoke tokens you created.
#     You also only SEE tokens you created — a Project owner cannot list collaborators' tokens.
#   * Automatic revocation: removing a member from a Workspace revokes the tokens they
#     minted for every Project in it; removing a collaborator revokes their tokens for that
#     Project; removing a Project from a custom group's access revokes the group members'
#     tokens for that Project.
# HTH Guide Excerpt: end token-rotation-notes

case "${MODE}" in
  scan)  rc=0; token_scan  || rc=$?; exit "${rc}" ;;
  probe) rc=0; token_probe || rc=$?; exit "${rc}" ;;
  *) echo "usage: $(basename "$0") [scan|probe]" >&2; exit 2 ;;
esac
