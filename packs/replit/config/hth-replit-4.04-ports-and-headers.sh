#!/usr/bin/env bash
# Control: 4.4 Minimize Exposed Ports and Set Security Headers
# Profile Level: L2 (Walk) | Plans: all
# Frameworks: NIST 800-53 CM-7/SC-7 | CIS Controls v8 4.4/12.2
# Guide: https://howtoharden.com/guides/replit/#44-minimize-exposed-ports-and-set-security-headers
# Interface: the .replit configuration file
#   Ports:   https://docs.replit.com/features/project-setup/ports
#   Headers: https://docs.replit.com/features/deployment-customization/static-deployments-advanced
# Run from the app's root (where .replit lives). Republish after any .replit change.
set -euo pipefail

REPLIT_FILE="${1:-.replit}"
[ -f "${REPLIT_FILE}" ] || { echo "No ${REPLIT_FILE} found — run from the app root."; exit 1; }

# HTH Guide Excerpt: begin ports-audit
# Audit every port mapping. Replit auto-binds the first non-localhost port to external 80.
# Services bound to localhost are NOT exposed unless exposeLocalhost is true — each such
# line is a deliberate decision to publish something that assumed it was local-only.
echo "== [[ports]] mappings in ${REPLIT_FILE} =="
awk '/^\[\[ports\]\]/{p=1} p&&/localPort|externalPort|exposeLocalhost/{print} /^$/{p=0}' "${REPLIT_FILE}"

if grep -qE '^[[:space:]]*exposeLocalhost[[:space:]]*=[[:space:]]*true' "${REPLIT_FILE}"; then
  echo "REVIEW 4.4: exposeLocalhost = true is set — confirm this service is meant to be public:"
  grep -nE '^[[:space:]]*exposeLocalhost[[:space:]]*=[[:space:]]*true' "${REPLIT_FILE}"
else
  echo "PASS 4.4: no exposeLocalhost = true entries."
fi
# Supported external ports: 80, 3000-3003, 4200, 5000, 5173, 6000, 6800, 8000, 8008, 8080, 8081.
# Ports 22 and 8283 are reserved by the platform and are not forwardable.
# HTH Guide Excerpt: end ports-audit

# HTH Guide Excerpt: begin static-security-headers
# Static deployments have no backend, so response headers are the only place browser-side
# defenses can live. Append this to .replit, then republish. Reserved headers that Replit
# blocks (do not attempt): Set-Cookie, Content-Length, Content-Encoding, Server, Location.
cat >> "${REPLIT_FILE}" <<'TOML'

[[deployment.responseHeaders]]
path = "/*"
name = "X-Frame-Options"
value = "DENY"

[[deployment.responseHeaders]]
path = "/*"
name = "X-Content-Type-Options"
value = "nosniff"

[[deployment.responseHeaders]]
path = "/*"
name = "Strict-Transport-Security"
value = "max-age=31536000; includeSubDomains"

[[deployment.responseHeaders]]
path = "/*"
name = "Referrer-Policy"
value = "strict-origin-when-cross-origin"
TOML
echo "Appended hardening headers to ${REPLIT_FILE} — republish, then verify at securityheaders.com"
# Note: the wildcard '*' is only supported at the END of a path pattern.
# HTH Guide Excerpt: end static-security-headers

# HTH Guide Excerpt: begin verify-headers-live
# Verify the published app actually returns the headers (republish first).
APP_URL="${REPLIT_APP_URL:-}"
if [ -n "${APP_URL}" ]; then
  curl -fsSI "${APP_URL}" | grep -iE 'x-frame-options|x-content-type-options|strict-transport-security|referrer-policy' \
    || echo "FAIL 4.4: expected headers not present — confirm the app was republished after the .replit change."
fi
# HTH Guide Excerpt: end verify-headers-live
