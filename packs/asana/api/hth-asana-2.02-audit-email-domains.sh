#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-2.2
#   guide:   https://howtoharden.com/guides/asana/#22-configure-domain-management
#   profile: L1
#   mode:    read-only
#   requires: ASANA_PAT(personal access token of any member of the organization), ASANA_WORKSPACE_GID, ASANA_APPROVED_EMAIL_DOMAINS(comma-separated)
# =============================================================================
# HTH Asana Control 2.2: Configure Domain Management
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.3 | NIST 800-53 AC-2
# Source: https://howtoharden.com/guides/asana/#22-configure-domain-management
# Dependencies: bash, curl (7.55+ for -H @file), jq
# API (verified against Asana's OpenAPI spec asana_oas.yaml, 2026-09-24):
#   GET /workspaces/{workspace_gid}?opt_fields=name,is_organization,email_domains   getWorkspace
#   WorkspaceResponse.email_domains: "The email domains that are associated with this workspace."
#   WorkspaceResponse.is_organization: "Whether the workspace is an *organization*."
#
# ── TRAP 1: this is a verification pack, not an enforcement pack ────────────
# PUT /workspaces/{workspace_gid} writes a WorkspaceRequest, whose only writable
# field is `name` ("Currently the only field that can be modified for a
# workspace is its name"). Adding, verifying or claiming a domain is console
# only; this pack proves the result.
#
# ── TRAP 2: a workspace is not an organization ──────────────────────────────
# Domain-based membership exists only on an organization. A workspace with
# is_organization=false has no email domains to govern, so it is reported as a
# finding rather than as an empty, passing domain list.
#
# ── TRAP 3: no approved list, no verdict ────────────────────────────────────
# ASANA_APPROVED_EMAIL_DOMAINS is required. Comparing the live list against
# nothing would pass every tenant, which is the fail-open this pack refuses.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, network, bad input, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_PAT "personal access token of a member of the organization"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
need ASANA_APPROVED_EMAIL_DOMAINS "comma-separated approved domains, e.g. example.com,example.org"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-202.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT
FINDINGS=0

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2.
# The token reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 60 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    exit 2
  fi
  if ! jq -e 'type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned a non-JSON body" >&2; exit 2
  fi
}

# HTH Guide Excerpt: begin email-domain-audit
asana_get "/workspaces/${ASANA_WORKSPACE_GID}?opt_fields=name,is_organization,email_domains"
if ! jq -e '.data | type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
  echo "PRECONDITION: workspace response carries no data object" >&2; exit 2
fi

echo "Asana 2.2 — organization email domains"
echo "  is_organization: $(jq -r '.data.is_organization // false' "${BODY_FILE}")"
if [ "$(jq -r '.data.is_organization // false' "${BODY_FILE}")" != "true" ]; then
  echo "FINDING: this gid is a workspace, not an organization; domain-based membership cannot be governed (TRAP 2)."
  FINDINGS=$((FINDINGS + 1))
fi

# Normalise both sides: lower-case, trimmed, de-duplicated.
live=$(jq -c '[.data.email_domains // [] | .[] | ascii_downcase] | unique' "${BODY_FILE}")
approved=$(jq -nc --arg a "${ASANA_APPROVED_EMAIL_DOMAINS}" \
  '[$a | split(",")[] | gsub("^\\s+|\\s+$"; "") | ascii_downcase | select(length > 0)] | unique')
if [ "$(jq -n --argjson a "${approved}" '$a | length')" -eq 0 ]; then
  echo "PRECONDITION: ASANA_APPROVED_EMAIL_DOMAINS holds no domains (TRAP 3)" >&2; exit 2
fi
echo "  live email_domains:     $(jq -nr --argjson l "${live}" '$l | join(", ")')"
echo "  approved email_domains: $(jq -nr --argjson a "${approved}" '$a | join(", ")')"

unexpected=$(jq -nc --argjson l "${live}" --argjson a "${approved}" '$l - $a')
missing=$(jq -nc --argjson l "${live}" --argjson a "${approved}" '$a - $l')
if [ "$(jq -n --argjson u "${unexpected}" '$u | length')" -gt 0 ]; then
  echo "FINDING: domains associated with the organization but not approved: $(jq -nr --argjson u "${unexpected}" '$u | join(", ")')"
  FINDINGS=$((FINDINGS + 1))
fi
if [ "$(jq -n --argjson m "${missing}" '$m | length')" -gt 0 ]; then
  echo "FINDING: approved domains not associated with the organization (accounts on them sit outside central control): $(jq -nr --argjson m "${missing}" '$m | join(", ")')"
  FINDINGS=$((FINDINGS + 1))
fi
# HTH Guide Excerpt: end email-domain-audit

if [ "${FINDINGS}" -gt 0 ]; then
  exit 1
fi
echo "COMPLIANT: the organization's email domains match the approved list exactly."
exit 0
