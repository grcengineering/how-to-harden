#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 9.1: Patch Next.js and Deny Spoofed Internal Headers
# Profile Level: L1 (Crawl)
# Frameworks: NIST SI-4, SI-10, SC-7
# Source: https://howtoharden.com/guides/vercel/#91-nextjs-patch-management--edge-header-strip
# Rationale: CVE-2025-29927 allowed attackers to bypass middleware-based
# authorization by spoofing the x-middleware-subrequest header. Even after
# patching Next.js, deny the spoofed middleware header as defense in
# depth. Do not block legitimate Next-Action or x-nextjs-data headers.
# Patch source: https://nextjs.org/blog/november-2026-security-release
# Verified floors: 2026-11-10. Recheck advisories before use.
# Reference: https://vercel.com/docs/vercel-firewall/vercel-waf/custom-rules
# API: PATCH /v1/security/firewall/config with action "rules.insert" (PUT would
#      REPLACE the whole firewall config). Persistence is the mitigate
#      "actionDuration"; there is no "persistentAction" field.
#      Opt-in MUTATING: inserts one custom rule, or updates it in place
#      ("rules.update" by id) when a rule of the same name is already in the
#      active config (GET /v1/security/firewall/config/active), so a re-run
#      adds no duplicates.
# Exit: 0 next at or above the LTS floor (optional rule applied only on opt-in); 1 next below the
#      floor or outside the LTS channels; 2 the patch gate had nothing to check
#      (no node_modules/next in the working directory).
# =============================================================================

set -euo pipefail

# HTH Guide Excerpt: begin api

# --- Patch gate: installed Next.js must be at or above the guide's LTS floor
#     (16.4.5 Active LTS, 15.5.29 Maintenance LTS) ---
echo ""
echo "=== Next.js patch coverage ==="
if [ -f node_modules/next/package.json ]; then
  NEXT_VERSION="$(jq -r '.version' node_modules/next/package.json)"
  if ! [[ "${NEXT_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "UNCHECKED: prerelease or malformed Next.js version; verify its advisory coverage separately."
    exit 2
  fi
  case "${NEXT_VERSION%%.*}" in
    16) FLOOR="16.4.5" ;;
    15) FLOOR="15.5.29" ;;
    *)  echo "BLOCK: next ${NEXT_VERSION} is outside the supported LTS channels (15.5.x, 16.4.x)."; exit 1 ;;
  esac
  if [ "$(printf '%s\n%s\n' "${FLOOR}" "${NEXT_VERSION%%-*}" | sort -V | head -1)" != "${FLOOR}" ]; then
    echo "BLOCK: next ${NEXT_VERSION} is below the ${FLOOR} floor."
    exit 1
  fi
  echo "OK: next ${NEXT_VERSION} >= ${FLOOR}"
else
  echo "UNCHECKED: no node_modules/next here -- run this from the application"
  echo "repository after installing dependencies (exit 2)."
  exit 2
fi

# Patching is mandatory. The additional WAF write is optional and only runs
# when explicitly enabled; Vercel already mitigates CVE-2025-29927 on its edge.
if [ "${HTH_APPLY_WAF_RULE:-0}" != "1" ]; then
  echo "Patch check complete; set HTH_APPLY_WAF_RULE=1 for the optional WAF rule."
  exit 0
fi
: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

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
  if ! printf '%s' "${resp}" | jq -e 'type == "object" and (has("error") | not) and (length > 0)' >/dev/null; then
    echo "ERROR: firewall update returned an empty, malformed, or error response; outcome unverified." >&2
    return 2
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
if ! printf '%s' "${ACTIVE_JSON}" | jq -e 'type == "object" and (has("error") | not) and (.rules | type == "array")' >/dev/null; then
  echo "ERROR: active firewall response is not a valid rule inventory; refusing to write." >&2
  exit 2
fi


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

# Next-Action and x-nextjs-data are legitimate framework headers, not evidence
# of an exploit. This pack no longer adds the old broad logging rule. Review
# any existing hth-log-nextjs-internal-headers rule before removing it manually.

# HTH Guide Excerpt: end api
