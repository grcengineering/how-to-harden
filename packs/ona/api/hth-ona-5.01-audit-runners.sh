#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-5.1
#   guide:   https://howtoharden.com/guides/ona/#51-run-self-hosted-runners-for-sensitive-source-code
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 5.1: Run Self-Hosted Runners for Sensitive Source Code
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 12.2
# Source: https://howtoharden.com/guides/ona/#51-run-self-hosted-runners-for-sensitive-source-code
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships `ona_runner`, `ona_runner_token` and `runner`/`runners`
# data sources, so Terraform is the right way to CREATE a self-hosted runner. It
# is the wrong way to audit one: the provider's own guide warns that the runner
# registration token is single-use, expires in 24 hours, and — though marked
# sensitive — IS STORED IN TERRAFORM STATE. Reading the fleet over the API needs
# no state file and mints no token.
#
# ── TRAP 1: RUNNER_KIND_LOCAL is deprecated, and there are TWO levers ───────
# `RUNNER_KIND_LOCAL` verbatim: "Deprecated: Local runners are no longer
# supported. Use RUNNER_PROVIDER_AWS_EC2 or RUNNER_PROVIDER_GCP instead."
# `RUNNER_KIND_LOCAL_CONFIGURATION` is different: "a system-managed runner that
# holds shared configuration for local runners. Every organization automatically
# has one… DesiredPhase. Can be set to STOPPED to disable all local runners." So
# local runners are governed by the org policy `allowLocalRunners` AND by that
# singleton's desiredPhase. This pack reads both, because either one left open is
# enough to keep local runners alive.
#
# ── TRAP 2: MANAGED and DEV_AGENT are internal-only providers ──────────────
# `RUNNER_PROVIDER_MANAGED` and `RUNNER_PROVIDER_DEV_AGENT` are both marked
# "Internal use only… Do not use when creating your own runners."  MANAGED is the
# Ona-operated fleet — i.e. exactly the NOT-self-hosted case this control exists
# to move away from, so it is counted separately rather than lumped in.
# `RUNNER_PROVIDER_LINUX_HOST` and `_DESKTOP_MAC` are deprecated too.
#
# ── TRAP 3: desiredPhase and status.phase are different facts ──────────────
# `spec.desiredPhase` is what you asked for; `status.phase` is what the runner
# reports. A runner can be desired ACTIVE and report DEGRADED. Both are printed;
# conflating them turns an outage into a compliance pass.
#
# ── TRAP 4: CreateRunner returns bootstrap credentials — never called here ──
# `CreateRunner` returns `accessToken` and `exchangeToken` once. This is a
# read-only pack; the only runner methods it touches are ListRunners and the
# organization policy read.
#
# Tunable: ONA_REQUIRE_SELF_HOSTED=1 — also fail when no AWS_EC2/GCP runner exists.
# Exit codes: 0 compliant | 1 finding | 2 precondition
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
# HTH Guide Excerpt: begin runner-fleet-audit
audit() {
  get_policies
  echo "Ona 5.1 — runner fleet and local-runner policy"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  paginate "RunnerService/ListRunners" '{}' "runners"
  local runners="${PAGE_ITEMS}" total self_hosted managed
  total=$(jq 'length' <<<"${runners}")
  # TRAP 2: self-hosted means AWS_EC2 or GCP; MANAGED is the Ona-operated fleet.
  self_hosted=$(jq '[.[] | select((.provider // "") == "RUNNER_PROVIDER_AWS_EC2" or (.provider // "") == "RUNNER_PROVIDER_GCP")] | length' <<<"${runners}")
  managed=$(jq '[.[] | select((.provider // "") == "RUNNER_PROVIDER_MANAGED")] | length' <<<"${runners}")
  echo "  runners: total=${total} self-hosted(AWS_EC2|GCP)=${self_hosted} Ona-managed=${managed}"

  # TRAP 3: desired vs reported, side by side.
  jq -r '.[] |
    "    - id=\…((.runnerId // "unknown")[-6:])" +
    " kind=\(.kind // "RUNNER_KIND_UNSPECIFIED")" +
    " provider=\(.provider // "RUNNER_PROVIDER_UNSPECIFIED")" +
    " desiredPhase=\(.spec.desiredPhase // "RUNNER_PHASE_UNSPECIFIED")" +
    " reportedPhase=\(.status.phase // "RUNNER_PHASE_UNSPECIFIED")"' <<<"${runners}"

  # TRAP 1: the second lever — the system-managed LOCAL_CONFIGURATION singleton.
  local lc_phase
  lc_phase=$(jq -r '[.[] | select((.kind // "") == "RUNNER_KIND_LOCAL_CONFIGURATION")
                         | (.spec.desiredPhase // "RUNNER_PHASE_UNSPECIFIED")]
                    | if length == 0 then "(no LOCAL_CONFIGURATION runner visible)" else .[0] end' <<<"${runners}")
  echo "  RUNNER_KIND_LOCAL_CONFIGURATION desiredPhase: ${lc_phase}"
  echo "    (set that singleton to RUNNER_PHASE_STOPPED to disable all local runners — the second"
  echo "     lever alongside allowLocalRunners)"

  local allow_local
  allow_local=$(jq -r '.allowLocalRunners // false' <<<"${POLICIES}")
  echo "  allowLocalRunners: ${allow_local} (absent in the JSON means false)"

  local rc=0
  if [ "${allow_local}" = "true" ]; then
    echo "FINDING: allowLocalRunners is true."
    echo "  Members can run environments on a machine the organization does not control, which puts"
    echo "  cloned source and mounted secrets on unmanaged hardware. Local runners are deprecated at"
    echo "  the enum level anyway — RUNNER_KIND_LOCAL says 'no longer supported'."
    rc=1
  fi
  if [ "${self_hosted}" -eq 0 ] && [ "${ONA_REQUIRE_SELF_HOSTED:-0}" = "1" ]; then
    echo "FINDING: no self-hosted runner exists (ONA_REQUIRE_SELF_HOSTED=1)."
    echo "  Every environment runs on Ona-operated infrastructure, so sensitive source is cloned"
    echo "  outside your own network boundary. Deploy an AWS_EC2 (CloudFormation) or GCP"
    echo "  (Terraform) runner and bind the sensitive projects to it."
    rc=1
  fi
  if [ "${self_hosted}" -eq 0 ] && [ "${ONA_REQUIRE_SELF_HOSTED:-0}" != "1" ]; then
    echo "NOTE: no self-hosted runner exists. Set ONA_REQUIRE_SELF_HOSTED=1 to score that as a"
    echo "  finding once your organization has decided sensitive source must stay on its own"
    echo "  infrastructure."
  fi
  if [ "${rc}" -eq 0 ]; then
    echo "COMPLIANT: local runners are not allowed and the fleet posture matches the expected profile."
  fi
  return "${rc}"
}
# HTH Guide Excerpt: end runner-fleet-audit

audit
