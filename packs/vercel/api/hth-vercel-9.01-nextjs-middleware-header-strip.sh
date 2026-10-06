#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 9.1: Strip Next.js Internal Headers at Edge
# Profile Level: L1 (Crawl)
# Frameworks: NIST SI-4, SI-10, SC-7
# Source: https://howtoharden.com/guides/vercel/#91-strip-nextjs-internal-headers
# Rationale: CVE-2025-29927 allowed attackers to bypass middleware-based
# authorization by spoofing the x-middleware-subrequest header. Even after
# patching Next.js, strip these internal headers at the edge as defense in
# depth. Also log x-nextjs-data and Next-Action probes from untrusted origins.
# Reference: https://zhero-web-sec.github.io/research-and-things/nextjs-and-the-corrupt-middleware
# API: PATCH /v1/security/firewall/config with action "rules.insert" (PUT would
#      REPLACE the whole firewall config). Persistence is the mitigate
#      "actionDuration"; there is no "persistentAction" field.
#      MUTATING: inserts two custom rules, or updates them in place
#      ("rules.update" by id) when a rule of the same name is already in the
#      active config (GET /v1/security/firewall/config/active), so a re-run
#      adds no duplicates.
# Exit: 0 rules deployed and next at or above the LTS floor; 1 next below the
#      floor or outside the LTS channels; 2 the patch gate had nothing to check
#      (no node_modules/next in the working directory).
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin api

# WARNING: if the Terraform module manages this project's firewall
# (vercel_firewall_config, 3.1/3.2), its next apply REPLACES the whole config
# and removes these rules. Manage custom rules in one place, not both.

FW_URL="https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}"

# curl -f aborts on HTTP 4xx/5xx; a 2xx body carrying .error also fails the run.
fw_patch() {
  local resp
  resp="$(curl -fsS -X PATCH \
    -H "Authorization: Bearer ${VERCEL_TOKEN}" \
    -H "Content-Type: application/json" \
    "${FW_URL}" -d @-)"
  if echo "${resp}" | jq -e 'type == "object" and has("error")' >/dev/null; then
    echo "${resp}" | jq '.error' >&2
    return 1
  fi
  echo "OK"
}

# A re-run must not duplicate rules (each duplicate also spends the plan's
# custom-rule quota), so a rule whose name already exists in the ACTIVE config is
# updated in place with "rules.update" instead of inserted again.
fw_upsert() {
  local body name id
  body="$(cat)"
  name="$(printf '%s' "${body}" | jq -r '.value.name')"
  id="$(printf '%s' "${ACTIVE_JSON}" | jq -r --arg n "${name}" '[.rules[]? | select(.name == $n) | .id][0] // empty')"
  if [ -n "${id}" ]; then
    echo "(rule ${name} already exists as ${id}: updating it in place)"
    printf '%s' "${body}" | jq -c --arg id "${id}" '{action: "rules.update", id: $id, value: .value}' | fw_patch
  else
    printf '%s' "${body}" | fw_patch
  fi
}

# --- Read the active firewall configuration once (for the upsert below) ---
ACTIVE_JSON="$(curl -fsS -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  "https://api.vercel.com/v1/security/firewall/config/active?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}")"

# --- WAF rule: DENY requests carrying x-middleware-subrequest, with a 24h
#     persistent block on the source (Section 3.3) ---
echo "=== Deploying WAF rule to deny x-middleware-subrequest ==="
fw_upsert <<'JSON'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-cve-2025-29927-deny-middleware-subrequest",
    "description": "Defense in depth for Next.js middleware auth bypass (CVE-2025-29927)",
    "active": true,
    "conditionGroup": [
      { "conditions": [ { "type": "header", "key": "x-middleware-subrequest", "op": "ex" } ] }
    ],
    "action": {
      "mitigate": {
        "action": "deny",
        "actionDuration": "24h"
      }
    }
  }
}
JSON

# --- WAF rule: LOG requests carrying x-nextjs-data / Next-Action (exploit precursors) ---
echo ""
echo "=== Logging suspicious Next.js internal headers ==="
fw_upsert <<'JSON'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-log-nextjs-internal-headers",
    "description": "Log probes of x-nextjs-data and Next-Action (exploit precursors)",
    "active": true,
    "conditionGroup": [
      { "conditions": [ { "type": "header", "key": "x-nextjs-data", "op": "ex" } ] },
      { "conditions": [ { "type": "header", "key": "next-action", "op": "ex" } ] }
    ],
    "action": {
      "mitigate": { "action": "log" }
    }
  }
}
JSON

# --- Patch gate: installed Next.js must be at or above the guide's LTS floor
#     (16.2.11 Active LTS, 15.5.21 Maintenance LTS) ---
echo ""
echo "=== Next.js patch coverage ==="
if [ -f node_modules/next/package.json ]; then
  NEXT_VERSION="$(jq -r '.version' node_modules/next/package.json)"
  case "${NEXT_VERSION%%.*}" in
    16) FLOOR="16.2.11" ;;
    15) FLOOR="15.5.21" ;;
    *)  echo "BLOCK: next ${NEXT_VERSION} is outside the supported LTS channels (15.5.x, 16.2.x)."; exit 1 ;;
  esac
  if [ "$(printf '%s\n%s\n' "${FLOOR}" "${NEXT_VERSION%%-*}" | sort -V | head -1)" != "${FLOOR}" ]; then
    echo "BLOCK: next ${NEXT_VERSION} is below the ${FLOOR} floor."
    exit 1
  fi
  echo "OK: next ${NEXT_VERSION} >= ${FLOOR}"
else
  echo "UNCHECKED: no node_modules/next here -- run this from the application"
  echo "repository after installing dependencies (exit 2; the WAF rules above were deployed)."
  exit 2
fi

# HTH Guide Excerpt: end api
