#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-6.2
#   guide:   https://howtoharden.com/guides/ona/#62-secure-webhooks-with-hmac-verification
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 6.2: Secure Webhooks with HMAC Verification
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 8.2
# Source: https://howtoharden.com/guides/ona/#62-secure-webhooks-with-hmac-verification
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships an `ona_webhook` resource and an EPHEMERAL
# `ona_webhook_secret`. Ephemeral resources are not persisted in state, so
# Terraform can create a webhook and hand you its secret once — it cannot tell
# you which webhooks already exist, which are still firing, or who can administer
# them. Those are the three facts this control needs, and all three are reads.
#
# ── TRAP 1: THE SECRET IS NEVER FETCHED HERE ───────────────────────────────
# `WebhookService/GetWebhookSecret` and `RotateWebhookSecret` both return the
# shared HMAC secret in plaintext. GetWebhookSecret is a `Get*` method and is
# still a credential-disclosure path — "Get" is not a safety guarantee. An
# evidence pack has no reason to hold that value, so neither is called.
#
# ── TRAP 2: THE API CONTRACT DOES NOT NAME THE HMAC ALGORITHM ──────────────
# `CreateWebhook` has no algorithm parameter and no signature-header parameter,
# and no page in the API reference states either. The secret is server-generated.
# So this pack can prove that webhooks EXIST and are LIVE; it cannot prove from
# the API alone how a receiver should verify them. Verification belongs to the
# receiver, and the guide's ClickOps half is where that lives.
#
# ── TRAP 3: lastTriggeredAt is the ONLY liveness evidence ──────────────────
# `boundWorkflowCount` shows coupling and `lastTriggeredAt` shows traffic. A
# webhook with zero bound workflows and no lastTriggeredAt is an unused inbound
# endpoint holding a live secret — the cleanup candidate. One that fires with
# nothing bound to it is stranger still, and worth a look.
#
# ── TRAP 4: Enterprise gating is a PRECONDITION, never a finding ───────────
# On a non-Enterprise organization ListWebhooks answers HTTP 400
# `failed_precondition` "feature is only available for enterprise customers".
# That is a plan boundary, so this pack exits 2 rather than reporting a control
# failure an operator cannot remediate.
#
# ── TRAP 5: WEBHOOK_ADMIN is a RESOURCE role, not an organization role ─────
# Webhook administration is granted by assigning `RESOURCE_ROLE_WEBHOOK_ADMIN`
# (48) or `_VIEWER` (49) TO A GROUP over `RESOURCE_TYPE_WEBHOOK` (42) via
# GroupService/CreateRoleAssignment. It will never show up in ListMembers, so the
# second read below is not optional colour — it is half the control.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (Enterprise-only, auth)
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

# Connect-RPC unary call. Every Ona method is a POST, but no -X flag is written:
# curl already implies POST when a body is supplied, which keeps this pack
# honestly read-only under scripts/validate-packs.sh check 14.
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
# HTH Guide Excerpt: begin webhook-inventory-audit
audit() {
  resolve_org
  echo "Ona 6.2 — webhook inventory and administration"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 4: probe once so the plan boundary is named, not swallowed.
  api "WebhookService/ListWebhooks" '{"pagination":{"pageSize":1}}'
  if [ "${RPC_CODE}" = "400" ] && [ "$(rpc_err)" = "failed_precondition" ]; then
    echo "PRECONDITION: webhooks are Enterprise-only on this organization — $(rpc_msg)" >&2
    echo "  The control cannot be evaluated on this plan tier; that is a licensing boundary," >&2
    echo "  not a misconfiguration." >&2
    exit 2
  fi
  if [ "${RPC_CODE}" != "200" ]; then
    api_strict "WebhookService/ListWebhooks" '{"pagination":{"pageSize":1}}'
  fi

  paginate "WebhookService/ListWebhooks" '{}' "webhooks"
  local hooks="${PAGE_ITEMS}" total idle
  total=$(jq 'length' <<<"${hooks}")
  echo "  webhooks: ${total}"
  # TRAP 1: no secret is read. TRAP 3: coupling and liveness, side by side.
  jq -r '.[] |
    "    - id=…\(((.id // "unknown")[-6:]))" +
    " name=\(.metadata.name // "(unnamed)")" +
    " provider=\(.spec.provider // "WEBHOOK_PROVIDER_UNSPECIFIED")" +
    " type=\(.spec.type // "WEBHOOK_TYPE_UNSPECIFIED")" +
    " boundWorkflowCount=\(.boundWorkflowCount // 0)" +
    " lastTriggeredAt=\(.lastTriggeredAt // "(never)")"' <<<"${hooks}"
  echo "  (the HMAC secret is not read — GetWebhookSecret discloses it in plaintext, TRAP 1)"

  idle=$(jq '[.[] | select((.boundWorkflowCount // 0) == 0) | select((.lastTriggeredAt // "") == "")] | length' <<<"${hooks}")

  # TRAP 5: who may administer webhooks is a RESOURCE role held by a GROUP.
  paginate "GroupService/ListRoleAssignments" \
           '{"filter":{"resourceTypes":["RESOURCE_TYPE_WEBHOOK"]}}' "assignments"
  local ras="${PAGE_ITEMS}" admins
  admins=$(jq '[.[] | select((.resourceRole // "") == "RESOURCE_ROLE_WEBHOOK_ADMIN")] | length' <<<"${ras}")
  echo "  webhook role assignments: total=$(jq 'length' <<<"${ras}") WEBHOOK_ADMIN=${admins}"
  jq -r '.[] | "    - group=…\(((.groupId // "unknown")[-6:])) role=\(.resourceRole // "RESOURCE_ROLE_UNSPECIFIED") derivedFromOrgRole=\(.derivedFromOrgRole // "RESOURCE_ROLE_UNSPECIFIED")"' <<<"${ras}"

  if [ "${total}" -eq 0 ]; then
    echo "COMPLIANT: no webhooks are configured — there is no inbound endpoint to sign or to leak."
    return 0
  fi
  if [ "${idle}" -gt 0 ]; then
    echo "FINDING: ${idle} webhook(s) have no bound workflow AND have never been triggered."
    echo "  Each one is a live inbound endpoint holding a server-generated secret that nothing"
    echo "  consumes. Delete them — DeleteWebhook returns affectedWorkflowIds so you can see what"
    echo "  breaks first — or rotate the secret and bind the workflow it was meant for."
    return 1
  fi
  echo "COMPLIANT: every webhook is either bound to a workflow or has fired at least once."
  echo "  Note: the API contract names no HMAC algorithm and no signature header (TRAP 2), so"
  echo "  receiver-side verification cannot be proven from here — verify it at the receiver."
  return 0
}
# HTH Guide Excerpt: end webhook-inventory-audit

audit
