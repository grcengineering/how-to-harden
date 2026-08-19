#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.5
#   guide:   https://howtoharden.com/guides/ona/#15-control-member-invitations-and-remove-domain-auto-admit
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(personal access token; Read-only is enough for the default audit), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 1.5: Control Member Invitations and Remove Domain Auto-Admit
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 6.1, 6.2
# Source: https://howtoharden.com/guides/ona/#15-control-member-invitations-and-remove-domain-auto-admit
# Dependencies: curl, jq
#
# WHY THIS PACK DECLARES `mode: mutating` DESPITE A READ-ONLY DEFAULT.
# `inviteDomains` lives on the ORGANIZATION object, and the `gitpod-io/ona`
# provider's 32-resource inventory contains no `ona_organization` resource —
# only `ona_organization_policies`, `ona_organization_ai_budget` and
# `ona_organization_role_assignment`, none of which carry it. There is likewise
# no `ona organization invite` CLI verb. Clearing the domain allow-list and
# rotating the invite link are therefore API or console only, so the two write
# branches live here beside the audit that motivates them. They use an explicit
# `-X POST`; declaring `read-only` on a file that can change who may join the
# organization would be a lie. Run with no arguments for evidence collection.
#
# ── TRAP 1: an EMPTY inviteDomains list is the hardened state ────────────────
# `InviteDomains.domains` — "the list of domains that are allowed to join the
# organization". Anyone with an address in a listed domain can self-admit. Proto3
# omits empty lists, so a hardened organization returns NO `inviteDomains` key at
# all. Absent == empty == good here, which is the ONE place in this guide where
# absence is the safe reading — and precisely why it must be reasoned about
# explicitly rather than by reflex.
#
# ── TRAP 2: the invite id IS the invite link ────────────────────────────────
# `GetOrganizationInvite` returns `invite.inviteId`, and the doc says "Use
# JoinOrganization with this ID to join the organization."  Anyone holding that
# id can join. It is a bearer credential in all but name, so this pack reports
# only THAT a link exists, never the id. Related:
# `GetOrganizationInviteSummary` shows an unauthenticated link-holder the
# organization name and member count — the link leaks even before it is used.
#
# ── TRAP 3: there is no per-email invite method ─────────────────────────────
# Nothing across the organization, account or user families resembles
# InviteMember/SendInvite. Email invitations are console-only. The API surface
# for 1.5 is exactly the shared link plus the domain allow-list, so a pack that
# claims to "audit invitations" can only mean these two things.
#
# ── TRAP 4: rotating the link does not remove anyone ────────────────────────
# `CreateOrganizationInvite` issues a NEW inviteId, which kills the old link. It
# does not touch members who already joined through it. Rotation is containment,
# not remediation — pair it with the 1.3 membership review.
#
# Exit codes: 0 compliant (or write applied) | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?set ONA_TOKEN — an Ona personal access token (Read-only is enough) or service account token}"

# TRAP (base URL). The documented base is https://app.ona.com/api. That host
# answers 308 to app.gitpod.io, and `curl -L` DROPS the Authorization header
# across the cross-host hop, so a valid token comes back 401. Default to the
# host that actually answers; override only for a custom management-plane
# domain (tokens must be minted on that same domain).
ONA_API_BASE="${ONA_API_BASE:-https://app.gitpod.io/api}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

RPC_BODY=""; RPC_CODE=""; ORG_ID=""; ORG_TIER=""; PAGE_ITEMS="[]"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-ona.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# Connect-RPC unary call for the READ paths. Every Ona method is a POST; the read
# helper relies on curl's implicit POST-with-body, while the two write branches
# below use an explicit `-X POST` — which is why this file is declared mutating.
api() {
  set +e
  RPC_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    "${ONA_API_BASE}/gitpod.v1.$1" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2" 2>/dev/null)
  local rc=$?
  set -e
  [ "${rc}" -eq 0 ] || RPC_CODE="000"
  RPC_BODY=$(cat "${BODY_FILE}" 2>/dev/null || echo '{}')
}

rpc_err() { printf '%s' "${RPC_BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown; }
rpc_msg() { printf '%s' "${RPC_BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message"; }

# Fatal classifier. Connect errors carry {"code": "...", "message": "..."}.
# Plan gating, auth failure and transport failure are all preconditions (exit 2),
# never findings — a control cannot be judged non-compliant on evidence that was
# never returned.
api_strict() {
  api "$1" "$2"
  if [ "${RPC_CODE}" = "200" ]; then return 0; fi
  case "${RPC_CODE}:$(rpc_err)" in
    400:failed_precondition)
      echo "PRECONDITION: $1 — $(rpc_msg)" >&2 ;;
    401:*|403:*)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2
      echo "  The token is invalid, expired, or lacks the permission this method requires." >&2 ;;
    000:*)
      echo "PRECONDITION: $1 — no HTTP response (network, DNS, or TLS failure)." >&2 ;;
    *)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2 ;;
  esac
  exit 2
}

# Follows pagination.nextToken to exhaustion. pageSize is capped at 100 by the
# API (int32.lte=100); the 200-page ceiling is a runaway guard, not a limit.
paginate() { # paginate <Service/Method> <base-json> <response-array-field>
  local method="$1" base="$2" field="$3" token="" req pages=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/hth-ona-page.XXXXXX")"
  while :; do
    req=$(jq -nc --argjson base "${base}" --arg t "${token}" \
      '$base + {pagination: ({pageSize: 100} + (if $t == "" then {} else {token: $t} end))}')
    api_strict "${method}" "${req}"
    printf '%s' "${RPC_BODY}" | jq -c --arg f "${field}" '.[$f][]?' >> "${tmp}"
    token=$(printf '%s' "${RPC_BODY}" | jq -r '.pagination.nextToken // ""')
    pages=$((pages + 1))
    [ -n "${token}" ] && [ "${pages}" -lt 200 ] || break
  done
  PAGE_ITEMS=$(jq -s '.' "${tmp}")
  rm -f "${tmp}"
}

# Organization id: explicit override, else derived from the token's own identity.
resolve_org() {
  if [ -n "${ONA_ORGANIZATION_ID:-}" ]; then ORG_ID="${ONA_ORGANIZATION_ID}"; ORG_TIER="(not read)"; return 0; fi
  api_strict "IdentityService/GetAuthenticatedIdentity" '{}'
  ORG_ID=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationId // ""')
  ORG_TIER=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationTier // "(unset)"')
  [ -n "${ORG_ID}" ] || { echo "PRECONDITION: GetAuthenticatedIdentity returned no organizationId" >&2; exit 2; }
}

# GetOrganizationPolicies is the single read anchor for every org-wide control.
# Proto3 JSON omits defaults, so callers must read every field with a `// false`,
# `// 0`, `// []` or `// "*_UNSPECIFIED"` fallback — absence is the default
# value, not an error and not compliance.
get_policies() {
  resolve_org
  api_strict "OrganizationService/GetOrganizationPolicies" \
    "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  POLICIES=$(printf '%s' "${RPC_BODY}" | jq -c '.policies // {}')
}
# HTH Guide Excerpt: begin invite-surface-audit
# The whole API-addressable surface of control 1.5: the domain allow-list on the
# organization object, and whether a shared invite link exists at all.
audit() {
  resolve_org
  api_strict "OrganizationService/GetOrganization" \
    "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  local org domains dcount
  org=$(printf '%s' "${RPC_BODY}" | jq -c '.organization // {}')

  echo "Ona 1.5 — invite surface (domain auto-admit and the shared invite link)"
  echo "  organization: …${ORG_ID: -6} tier=$(jq -r '.tier // "ORGANIZATION_TIER_UNSPECIFIED"' <<<"${org}")"

  # TRAP 1: absent inviteDomains == empty == hardened.
  domains=$(jq -c '.inviteDomains.domains // []' <<<"${org}")
  dcount=$(jq 'length' <<<"${domains}")
  echo "  inviteDomains.domains: ${dcount} entr$( [ "${dcount}" -eq 1 ] && echo y || echo ies )"
  if [ "${dcount}" -gt 0 ]; then
    jq -r '.[] | "    ! \(.)"' <<<"${domains}"
  fi

  # TRAP 2: prove the link exists without printing the id that IS the link.
  api "OrganizationService/GetOrganizationInvite" \
      "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  local invite_state
  if [ "${RPC_CODE}" = "200" ]; then
    if [ -n "$(printf '%s' "${RPC_BODY}" | jq -r '.invite.inviteId // ""')" ]; then
      invite_state="present"
    else
      invite_state="absent"
    fi
  elif [ "${RPC_CODE}" = "404" ]; then
    invite_state="absent"
  else
    invite_state="unreadable (HTTP ${RPC_CODE} $(rpc_err))"
  fi
  echo "  shared invite link: ${invite_state} (the id is withheld — it is a join credential)"
  if [ "${invite_state}" = "present" ]; then
    echo "    Anyone holding it can call JoinOrganization, and GetOrganizationInviteSummary"
    echo "    already discloses the organization name and member count to a link-holder."
    echo "    Rotate it with --reset-invite-link whenever it may have been shared outside."
  fi

  if [ "${dcount}" -gt 0 ]; then
    echo "FINDING: ${dcount} domain(s) auto-admit new members to this organization."
    echo "  Every current and future mailbox in those domains — contractors, shared aliases,"
    echo "  a re-registered ex-employee address — can join without an approval step."
    echo "  Clear the list with --clear-invite-domains and admit members through SSO/SCIM (1.1, 1.2)."
    return 1
  fi
  echo "COMPLIANT: inviteDomains is empty — no domain auto-admits into this organization."
  return 0
}
# HTH Guide Excerpt: end invite-surface-audit

# HTH Guide Excerpt: begin invite-surface-remediation
# UpdateOrganization echoes the organization back, so unlike the policies write
# this one IS self-verifying — but it is read back anyway, because the echo is
# the server's copy of the request and a separate GET is the honest proof.
clear_invite_domains() {
  resolve_org
  local code
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' -X POST \
    "${ONA_API_BASE}/gitpod.v1.OrganizationService/UpdateOrganization" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o, inviteDomains: {domains: []}}')")
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: UpdateOrganization returned HTTP ${code} — $(jq -r '.message // "no message"' < "${BODY_FILE}")" >&2
    exit 2
  fi
  api_strict "OrganizationService/GetOrganization" "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  local remaining
  remaining=$(printf '%s' "${RPC_BODY}" | jq '(.organization.inviteDomains.domains // []) | length')
  echo "read-back: inviteDomains.domains now has ${remaining} entries"
  [ "${remaining}" -eq 0 ] || { echo "the write did not stick — ${remaining} domain(s) remain" >&2; exit 1; }
}

# TRAP 4: a new inviteId invalidates the old link; it removes nobody.
reset_invite_link() {
  resolve_org
  local code
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' -X POST \
    "${ONA_API_BASE}/gitpod.v1.OrganizationService/CreateOrganizationInvite" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')")
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: CreateOrganizationInvite returned HTTP ${code} — $(jq -r '.message // "no message"' < "${BODY_FILE}")" >&2
    exit 2
  fi
  if [ -n "$(jq -r '.invite.inviteId // ""' < "${BODY_FILE}")" ]; then
    echo "invite link rotated: a new invite id was issued, so the previous link no longer joins."
    echo "  The id is withheld here on purpose — retrieve it from the console when you distribute it."
    echo "  Members who already joined through the old link are NOT removed; review them under 1.3."
  else
    echo "CreateOrganizationInvite returned 200 but no inviteId — treat the rotation as unproven" >&2
    exit 1
  fi
}
# HTH Guide Excerpt: end invite-surface-remediation

case "${1:-}" in
  ""|audit)                audit ;;
  --clear-invite-domains)  clear_invite_domains ;;
  --reset-invite-link)     reset_invite_link ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-ona-1.05-audit-invite-surface.sh                          # read-only audit (default)
  hth-ona-1.05-audit-invite-surface.sh --clear-invite-domains   # empty the domain allow-list, then read back
  hth-ona-1.05-audit-invite-surface.sh --reset-invite-link      # issue a new invite id, killing the old link
USAGE
    exit 2 ;;
esac
