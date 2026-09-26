#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-4.4
#   guide:   https://howtoharden.com/guides/replit/#44-minimize-exposed-ports-and-set-security-headers
#   profile: L2
#   mode:    mutating
#   requires: a .replit file (path as $2, default ./.replit); REPLIT_APP_URL(optional, published Static Deployment URL for the live header check)
# =============================================================================
# HTH Replit Control 4.4: Minimize Exposed Ports and Set Security Headers
# Profile Level: L2 (Walk) | Plans: all
# Frameworks: NIST 800-53 CM-7/SC-7 | CIS Controls v8 4.4/12.2
# Sources: https://docs.replit.com/features/project-setup/ports
#          https://docs.replit.com/features/deployment-customization/static-deployments-advanced
# Dependencies: awk, grep, curl (live check)
#
# WHY `mode: mutating` DESPITE A READ-ONLY DEFAULT.
# The default invocation (`audit`) only READS .replit and, when REPLIT_APP_URL is
# set, sends one GET to the published app. `--apply-headers` APPENDS
# [[deployment.responseHeaders]] entries to .replit — a real change to the app's
# configuration — so the file as a whole is declared mutating. The write never
# fires unless you name it.
#
# Usage:  hth-replit-4.04-ports-and-headers.sh [audit|--apply-headers] [path/to/.replit]
# Exit codes: 0 compliant | 1 finding | 2 precondition (nothing was verified)
# =============================================================================

set -euo pipefail

MODE="${1:-audit}"
REPLIT_FILE="${2:-.replit}"
HEADERS="X-Frame-Options X-Content-Type-Options Strict-Transport-Security Referrer-Policy"

[ -f "${REPLIT_FILE}" ] || { echo "ERROR 4.4: no ${REPLIT_FILE} found — run from the app root or pass its path" >&2; exit 2; }

# HTH Guide Excerpt: begin ports-audit
# Audit every [[ports]] mapping. Replit binds the first port you open to external 80;
# services on localhost are NOT exposed unless exposeLocalhost = true (or unless a user
# sets "automatic port forwarding" to "All ports" in the User Settings tool) — each
# exposeLocalhost line publishes something that was written assuming it was local-only.
ports_audit() {
  local external rc=0
  echo "== [[ports]] mappings in ${REPLIT_FILE} =="
  awk '/^\[\[ports\]\]/{p=1; print; next} /^\[/{p=0} p&&/localPort|externalPort|exposeLocalhost/{print "  " $0}' "${REPLIT_FILE}"
  external=$(grep -cE '^[[:space:]]*externalPort[[:space:]]*=' "${REPLIT_FILE}" || true)
  echo "external ports mapped: ${external}"
  if [ "${external}" -gt 1 ]; then
    echo "REVIEW 4.4: Autoscale and Reserved VM deployments support ONE external port — publishing fails with more; keep only the port the internet needs."
  fi
  if grep -nE '^[[:space:]]*exposeLocalhost[[:space:]]*=[[:space:]]*true' "${REPLIT_FILE}"; then
    echo "FAIL 4.4: exposeLocalhost = true (above) publishes a localhost-bound service — remove it unless that service is meant to face the internet."
    rc=1
  else
    echo "PASS 4.4: no exposeLocalhost = true entries."
  fi
  # Supported extra external ports: 3000-3003, 4200, 5000, 5173, 6000, 6800, 8000, 8008,
  # 8080, 8081 (80 is the default). Ports 22 and 8283 are used internally, not forwardable.
  return "${rc}"
}
# HTH Guide Excerpt: end ports-audit

# HTH Guide Excerpt: begin static-security-headers
# Static Deployments have no backend, so [[deployment.responseHeaders]] in .replit is the
# only place browser-side defenses can live. Append only the headers that are missing, so
# a re-run never duplicates a block, then republish. Replit reserves (and rejects) headers
# such as Set-Cookie, Server, Location, Content-Length and Content-Encoding. The docs name
# no .replit key that identifies a Static Deployment, so confirm the deployment type in
# the Publishing tool before running this.
apply_headers() {
  local name value added=0
  for name in ${HEADERS}; do
    if grep -qE "^[[:space:]]*name[[:space:]]*=[[:space:]]*\"${name}\"" "${REPLIT_FILE}"; then
      echo "present: ${name}"
      continue
    fi
    case "${name}" in
      X-Frame-Options)           value="DENY" ;;
      X-Content-Type-Options)    value="nosniff" ;;
      Strict-Transport-Security) value="max-age=31536000; includeSubDomains" ;;
      Referrer-Policy)           value="strict-origin-when-cross-origin" ;;
    esac
    printf '\n[[deployment.responseHeaders]]\npath = "/*"\nname = "%s"\nvalue = "%s"\n' "${name}" "${value}" >> "${REPLIT_FILE}"
    echo "appended: ${name}"
    added=$((added + 1))
  done
  echo "${added} header block(s) appended to ${REPLIT_FILE} — republish, then run this pack again with REPLIT_APP_URL set."
  # The wildcard '*' is only valid at the END of a path pattern.
}
# HTH Guide Excerpt: end static-security-headers

# HTH Guide Excerpt: begin verify-headers-live
# Verify the published app returns EVERY header (republish first). A fetch failure or a
# redirect proves nothing, so both are reported as errors rather than as a pass.
verify_headers() {
  local hdrs code rc=0 miss=0 name
  hdrs=$(curl -sS -D - -o /dev/null --max-time 30 "${REPLIT_APP_URL}") || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "ERROR 4.4: could not fetch ${REPLIT_APP_URL} (curl exit ${rc}) — headers not verified" >&2
    return 2
  fi
  code=$(printf '%s\n' "${hdrs}" | awk 'NR==1{print $2}')
  case "${code}" in
    2??) ;;
    *) echo "ERROR 4.4: ${REPLIT_APP_URL} answered HTTP ${code} — point REPLIT_APP_URL at a public page of the Static Deployment" >&2; return 2 ;;
  esac
  for name in ${HEADERS}; do
    if printf '%s\n' "${hdrs}" | grep -qi "^${name}:"; then
      echo "present: ${name}"
    else
      echo "FAIL 4.4: ${name} missing from ${REPLIT_APP_URL}"
      miss=1
    fi
  done
  return "${miss}"
}
# HTH Guide Excerpt: end verify-headers-live

case "${MODE}" in
  audit)
    result=0
    ports_audit || result=$?
    if [ -n "${REPLIT_APP_URL:-}" ]; then
      rc=0; verify_headers || rc=$?
      if [ "${rc}" -gt "${result}" ]; then result="${rc}"; fi
    else
      echo "SKIP 4.4: REPLIT_APP_URL unset — live header check not run"
    fi
    exit "${result}"
    ;;
  --apply-headers) apply_headers ;;
  *) echo "usage: $(basename "$0") [audit|--apply-headers] [path/to/.replit]" >&2; exit 2 ;;
esac
