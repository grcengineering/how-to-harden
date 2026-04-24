#!/usr/bin/env bash
# =============================================================================
# HTH Vercel Control 9.1: Strip Next.js Internal Headers at Edge
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-4, SI-10, SC-7
# Source: https://howtoharden.com/guides/vercel/#91-strip-nextjs-internal-headers
# Rationale: CVE-2025-29927 allowed attackers to bypass middleware-based
# authorization by spoofing the x-middleware-subrequest header. Even after
# patching Next.js, strip these internal headers at the edge as defense in
# depth. Also strip x-nextjs-data and Next-Action from untrusted origins.
# Reference: https://zhero-web-sec.github.io/research-and-things/nextjs-and-the-corrupt-middleware
# =============================================================================

set -euo pipefail

: "${VERCEL_TOKEN:?Set VERCEL_TOKEN}"
: "${VERCEL_TEAM_ID:?Set VERCEL_TEAM_ID}"
: "${VERCEL_PROJECT_ID:?Set VERCEL_PROJECT_ID}"

# HTH Guide Excerpt: begin api

# --- WAF rule: DENY requests that carry x-middleware-subrequest from the public internet ---
echo "=== Deploying WAF rule to deny x-middleware-subrequest ==="
curl -s -X PUT \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
  -d @- <<'JSON' | jq '.'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-cve-2025-29927-deny-middleware-subrequest",
    "description": "Defense in depth for Next.js middleware auth bypass (CVE-2025-29927)",
    "active": true,
    "conditionGroup": [
      {
        "conditions": [
          {
            "type": "header",
            "key": "x-middleware-subrequest",
            "op": "ex"
          }
        ]
      }
    ],
    "action": {
      "mitigate": {
        "action": "deny",
        "actionDuration": "permanent",
        "persistentAction": true
      }
    }
  }
}
JSON

# --- WAF rule: LOG requests carrying x-nextjs-data / Next-Action (exploit precursor) ---
echo ""
echo "=== Logging suspicious Next.js internal headers ==="
curl -s -X PUT \
  -H "Authorization: Bearer ${VERCEL_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://api.vercel.com/v1/security/firewall/config?projectId=${VERCEL_PROJECT_ID}&teamId=${VERCEL_TEAM_ID}" \
  -d @- <<'JSON' | jq '.'
{
  "action": "rules.insert",
  "id": null,
  "value": {
    "name": "hth-log-nextjs-internal-headers",
    "description": "Log probes of x-nextjs-data and Next-Action (exploit precursors)",
    "active": true,
    "conditionGroup": [
      {
        "conditions": [
          {
            "type": "header",
            "key": "x-nextjs-data",
            "op": "ex"
          }
        ]
      },
      {
        "conditions": [
          {
            "type": "header",
            "key": "next-action",
            "op": "ex"
          }
        ]
      }
    ],
    "action": {
      "mitigate": {
        "action": "log"
      }
    }
  }
}
JSON

# --- Report current Next.js version pinned in package.json (patch coverage gate) ---
echo ""
echo "=== Next.js patch coverage ==="
if [ -f package.json ]; then
  NEXT_VERSION="$(jq -r '.dependencies.next // .devDependencies.next // empty' package.json)"
  if [ -z "${NEXT_VERSION}" ]; then
    echo "next not in dependencies — skip."
  else
    echo "next: ${NEXT_VERSION}"
    cat <<'ADVISORIES'
Known high/critical Next.js CVEs (verify your pin is at or above the fix):
  CVE-2025-29927 : Middleware auth bypass    Fix: 12.3.5 / 13.5.9 / 14.2.25 / 15.2.3
  CVE-2024-46982 : Pages Router cache poison Fix: 13.5.7 / 14.2.10
  CVE-2024-34351 : Server Actions SSRF       Fix: 14.1.1
  CVE-2025-49826 : 204 cache poison DoS      Fix: 15.1.8
  CVE-2025-55182 : React Server Components RCE ("React2Shell")  Fix: 15.5.7 / 16.0.7
  CVE-2025-55183 : RSC source code exposure  Fix: same as React2Shell
  CVE-2025-55184 : RSC DoS                    Fix: same as React2Shell
  CVE-2026-23869 : App Router RSC deserialization DoS  Fix: 15.5.15 / 16.2.3
ADVISORIES
  fi
fi

# HTH Guide Excerpt: end api
