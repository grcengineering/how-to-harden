#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-4.2
#   guide:   https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(not used directly — the in-environment CLI is already authenticated)
# =============================================================================
# HTH Ona Control 4.2: Use OIDC Workload Identity — verify the token subject
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 16.9 | NIST 800-53 IA-5, AC-3
# Source: https://ona.com/docs/ona/configuration/oidc.md
#
# WHY cli/: `ona idp token` is the only documented way to mint an Ona OIDC token,
# and `ona idp login aws|vault` is the documented keyless path. There is no REST
# endpoint for this in the public API reference, so cli/ is the honest surface.
#
# WHAT IT DOES: mints an ID token for an audience, decodes it, and reports the
# `iss` and the SHAPE of `sub` — which is what you actually paste into a cloud
# IAM trust policy. Asserts `iss == https://app.gitpod.io`. It never prints the
# token, and it truncates every id in the subject to 8 characters.
#
# THIS RUNS INSIDE AN ONA ENVIRONMENT. `ona idp token` mints for the calling
# principal; from a laptop you get a *user* token (or nothing), not the
# *environment* token your cloud trust policy is written against. The pack
# detects that by the command failing — there is no environment marker variable
# documented, so nothing is guessed — and exits 2.
#
# -----------------------------------------------------------------------------
# THE KEYLESS PATH THIS CONTROL IS ABOUT
# -----------------------------------------------------------------------------
#   ona idp login aws   --role-arn arn:aws:iam::123456789012:role/OnaRole
#   ona idp login vault --role my-role
# Register `https://app.gitpod.io` as the issuer with the cloud provider, then
# write the trust rule against the claims below. No static cloud key is stored.
#
# -----------------------------------------------------------------------------
# TRAPS
# -----------------------------------------------------------------------------
# T1  V2 AND V3 SUBJECTS ARE DIFFERENT FORMATS, AND SWITCHING BREAKS TRUST
#     POLICIES. V3 (current): colon-delimited key:value pairs —
#     `organization_id:<orgID>:project_id:<projID>`. V2 (legacy): a slash path —
#     `org:<orgID>/prj:<projID>/env:<envID>`. Vendor warning: "Switching from V2
#     to V3 changes the `sub` claim format. Update your cloud provider trust
#     policies before switching." This pack prints which format it saw.
# T2  THE ENVIRONMENT SUBJECT DEPENDS ON WHETHER A PROJECT EXISTS. With a
#     project: `organization_id:…:project_id:…`. Without one: `organization_id:…`
#     alone — a trust policy keyed on project_id silently stops matching for
#     ad-hoc environments.
# T3  EXTRA SUB FIELDS CAN CARRY AN EMAIL. `creator_email` and `email` are
#     configurable extra sub fields, so `sub` is not always id-only. Anything
#     email-shaped is redacted below before printing.
# T4  THE `--decode` RENDERING IS NOT DOCUMENTED. This pack parses it when it is
#     JSON and otherwise decodes the JWT payload itself, so it does not depend on
#     an unpublished output format.
# T5  OIDC IS ENTERPRISE-PLAN ONLY, and the token version is an org setting
#     (Settings → Security → OIDC Token Configuration). A failure here can mean
#     "not entitled" rather than "misconfigured".
#
# Requires: `ona` on PATH (pre-installed in every Ona environment), jq (>= 1.6
#           for @base64d). Reads only — mints a short-lived ID token, changes
#           nothing.
# =============================================================================

set -euo pipefail

AUD="${AUD:-sts.amazonaws.com}"
ONA_BIN="${ONA_BIN:-ona}"
EXPECTED_ISS="https://app.gitpod.io"

command -v "${ONA_BIN}" >/dev/null 2>&1 || {
  echo "PRECONDITION: '${ONA_BIN}' not on PATH. This pack runs inside an Ona environment." >&2
  exit 2; }
command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq (>= 1.6) required." >&2; exit 2; }

# HTH Guide Excerpt: begin cli-oidc-subject-verify
# Mint an OIDC token for an audience and report its issuer and subject shape.
# The token itself is never printed; ids are truncated to 8 characters.

# base64url -> JSON. Used only if `--decode` does not hand back JSON (T4).
b64url_json() {
  local seg="$1" pad=$(( 4 - ${#1} % 4 ))
  [ "${pad}" -eq 4 ] || seg="${seg}$(printf '=%.0s' $(seq 1 "${pad}"))"
  printf '%s' "${seg}" | tr '_-' '/+' | jq -Rr '@base64d' 2>/dev/null || true
}

decode_token() {
  local out raw payload
  # Documented form. If this fails we are not a principal that can mint here.
  if out="$("${ONA_BIN}" idp token --audience "${AUD}" --decode 2>/dev/null)"; then
    # Take the first JSON object out of whatever it printed.
    if printf '%s' "${out}" | sed -n '/{/,$p' | jq -e . >/dev/null 2>&1; then
      printf '%s' "${out}" | sed -n '/{/,$p'
      return 0
    fi
  fi
  # Fallback: decode the JWT payload ourselves. The raw token stays in this
  # function and is never echoed.
  raw="$("${ONA_BIN}" idp token --audience "${AUD}" 2>/dev/null | tr -d '[:space:]')" || return 1
  [ -n "${raw}" ] || return 1
  payload="$(printf '%s' "${raw}" | cut -d. -f2)"
  [ -n "${payload}" ] || return 1
  b64url_json "${payload}"
}

claims="$(decode_token || true)"
if [ -z "${claims}" ] || ! printf '%s' "${claims}" | jq -e . >/dev/null 2>&1; then
  echo "PRECONDITION: could not mint or decode an OIDC token for audience '${AUD}'." >&2
  echo "  Most likely you are not inside an Ona environment. 'ona idp token' mints" >&2
  echo "  for the calling principal, so run this from a task, a terminal in the" >&2
  echo "  environment, or 'ona environment exec <id> -- ...'." >&2
  echo "  Other causes: OIDC is Enterprise-plan only, and the org may not have it" >&2
  echo "  enabled (Settings > Security > OIDC Token Configuration)." >&2
  exit 2
fi

iss="$(printf '%s' "${claims}" | jq -r '.iss // ""')"
sub="$(printf '%s' "${claims}" | jq -r '.sub // ""')"

# Redact email-shaped values (T3), then truncate every id-looking token to 8
# characters so the subject SHAPE is legible without publishing identifiers.
sub_shape="$(printf '%s' "${sub}" \
  | sed -E 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/<redacted-email>/g' \
  | sed -E 's/([0-9a-fA-F]{8})[0-9a-fA-F-]{4,}/\1…/g')"

case "${sub}" in
  *"/"*) sub_format="V2 (legacy path format — see T1)" ;;
  *)     sub_format="V3 (current key:value format)" ;;
esac

echo "audience:      ${AUD}"
echo "issuer:        ${iss}"
echo "subject shape: ${sub_shape}"
echo "subject format: ${sub_format}"
echo "claims present: $(printf '%s' "${claims}" | jq -r '[keys[]] | join(", ")')"

if [ "${iss}" != "${EXPECTED_ISS}" ]; then
  echo "FINDING: issuer is '${iss}', expected '${EXPECTED_ISS}'." >&2
  echo "         Register '${EXPECTED_ISS}' as the OIDC issuer in your cloud IAM," >&2
  echo "         or correct the custom management-plane domain in your trust policy." >&2
  exit 1
fi

echo "COMPLIANT: issuer is ${EXPECTED_ISS}. Scope the cloud trust policy on the"
echo "           subject above, then authenticate keylessly with:"
echo "             ona idp login aws   --role-arn <role-arn>"
echo "             ona idp login vault --role <role>"
exit 0
# HTH Guide Excerpt: end cli-oidc-subject-verify
