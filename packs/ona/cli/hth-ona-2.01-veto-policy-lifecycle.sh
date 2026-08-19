#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.1
#   guide:   https://howtoharden.com/guides/ona/#21-enforce-an-executable-policy-with-veto
#   profile: L2
#   mode:    mutating
#   requires: ONA_TOKEN(personal access token, Read & Write — this pack creates and assigns a policy)
# =============================================================================
# HTH Ona Control 2.1: Enforce an Executable Policy with Veto — policy lifecycle
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5, 2.7 | NIST 800-53 CM-7, SI-3 | NIST AI RMF MANAGE-2.3
# Source: https://ona.com/docs/ona/organizations/policies/executable-deny-list.md
#         https://ona.com/docs/ona/reference/cli.md
#
# WHY cli/: Ona ships a first-party `ona` CLI and the Veto Exec runbook is written
# entirely in it (`ona organization security-policy init|create|set-default|list`).
# The SecurityService REST API exists too, but the CLI is the surface the vendor
# documents end to end for this control, including the validate-before-send step.
#
# THE POLICY DOCUMENT LIVES IN ITS OWN PACK — this script does not inline it:
#   packs/ona/config/hth-ona-2.01-veto-exec-policy.yml
# Point ONA_VETO_POLICY_FILE at that file (or a copy you have edited).
#
# -----------------------------------------------------------------------------
# THE FOUR-STEP SEQUENCE (and the guide error it corrects)
# -----------------------------------------------------------------------------
#   1. init <file> --validate-only   client-side schema validation
#   2. create <file> -o yaml         stores an INACTIVE definition, returns an id
#   3. set-default <policy-id>       assigns it to newly created environments
#   4. list -o json                  presence check only (see verify_default)
# `set-default` takes a POLICY ID, never a filename. Passing the YAML file to
# set-default is a documented mis-reading of this runbook; the id comes back from
# `create`. Vendor: "Copy the returned policy ID and assign it as the
# organization default."
#
# -----------------------------------------------------------------------------
# TRAPS (all read from executable-deny-list.md, 2026-08-19)
# -----------------------------------------------------------------------------
# T1  CREATION IS NOT ACTIVATION. "Creation stores an inactive policy definition.
#     The CLI validates file input before sending it, but the management plane's
#     authoritative materializability check runs on default assignment. An
#     unassigned policy can later be rejected when assigned." A green `create` is
#     not evidence; only step 3 exercising the real check is.
# T2  RUNNING ENVIRONMENTS DO NOT PICK THIS UP. "New environments receive the
#     assigned policy. Restart an existing environment to apply the current
#     organization default. An already-running environment keeps the policy from
#     its last start." Nothing in this script changes a live environment.
# T3  `set-default --clear` IS NOT AN UNDO FOR EXECUTABLE RULES. "Clearing the
#     default removes every control in that SecurityPolicy, not only executable
#     rules." The documented rollback for Veto Exec is to flip each rule back to
#     EFFECT_AUDIT and `update` — which keeps audit visibility and every other
#     control in the policy. --clear is behind a literal CONFIRM argument here.
# T4  RULE EFFECTS ARE CONSTRAINED. `defaultEffect` may be omitted or
#     EFFECT_ALLOW; each rule must be EFFECT_AUDIT or EFFECT_BLOCK. "An
#     executable rule cannot use EFFECT_ALLOW."
# T5  SELECTORS ARE ABSOLUTE PATHS OR BARE NAMES ONLY. `.`, `..`, `./npx` and
#     relative paths such as `tools/npx` are invalid after trimming.
# T6  BLOCKING AN INTERPRETER CAN BRICK AN ENVIRONMENT. Vendor warning: blocking
#     `/bin/bash` "also blocks scripts that use that interpreter and can make an
#     environment unusable. Test interpreter rules in audit mode first."
# T7  THE SAFELIST CANNOT BE BLOCKED. "Veto safelists Ona runtime binaries by
#     content hash and cannot block them." A rule naming one is silently inert.
# T8  Veto Exec is Enterprise-plan only, and its audit-log entries are
#     preview-gated. A policy can be assigned and enforcing while no audit entry
#     is visible, so do not treat an empty audit query as "not enforcing".
#
# Requires: `ona` on PATH and authenticated (`export ONA_TOKEN=...; ona login`),
#           or `ona login --token "<token>"` / `ona login --non-interactive`.
#           jq for the id extraction and the assignment proof.
# Install:  brew install gitpod-io/tap/ona
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?export ONA_TOKEN with a Read & Write personal access token (https://app.ona.com/settings/personal-access-tokens), then run: ona login}"

POLICY_FILE="${ONA_VETO_POLICY_FILE:-packs/ona/config/hth-ona-2.01-veto-exec-policy.yml}"
ONA_BIN="${ONA_BIN:-ona}"

require_cli() {
  command -v "${ONA_BIN}" >/dev/null 2>&1 || {
    echo "PRECONDITION: '${ONA_BIN}' not on PATH. brew install gitpod-io/tap/ona" >&2
    exit 2
  }
  command -v jq >/dev/null 2>&1 || { echo "PRECONDITION: jq required." >&2; exit 2; }
}

# The CLI is pre-installed and limited-access-authenticated inside every Ona
# environment; org-admin writes need a real login. Do this once, never in argv
# where the token would land on the process table.
authenticate() {
  "${ONA_BIN}" whoami >/dev/null 2>&1 && return 0
  "${ONA_BIN}" login --non-interactive >/dev/null 2>&1 && return 0
  echo "PRECONDITION: not authenticated. Run 'ona login' (browser) or" >&2
  echo "              'ona login --token \"\$ONA_TOKEN\"' first." >&2
  exit 2
}

# HTH Guide Excerpt: begin cli-veto-policy-apply
# Apply the Veto Exec executable policy and assign it as the organization
# default. Audit-first: every rule in the shipped policy is EFFECT_AUDIT.
apply_policy() {
  local file="$1"
  [ -r "${file}" ] || { echo "FATAL: policy file not readable: ${file}" >&2; exit 2; }

  # Step 1 — client-side validation. Cheap, and it catches T4/T5 before the
  # management plane ever sees the document.
  echo "==> validating ${file}"
  "${ONA_BIN}" organization security-policy init "${file}" --validate-only

  # Step 2 — create. This stores an INACTIVE definition (T1) and returns it.
  # `-o yaml` is the form the vendor runbook uses; `-o json` is parseable, so
  # that is what we ask for here in order to lift the id deterministically.
  echo "==> creating policy"
  local created policy_id
  created="$("${ONA_BIN}" organization security-policy create "${file}" -o json)"
  policy_id="$(printf '%s' "${created}" \
    | jq -r '.. | objects | (.securityPolicyId? // .id?) | select(type=="string" and test("^[0-9a-fA-F-]{36}$"))' \
    | head -n1)"
  [ -n "${policy_id}" ] || {
    echo "FATAL: could not read a policy id out of the create response." >&2
    echo "       Re-run 'ona organization security-policy create ${file} -o yaml'" >&2
    echo "       and assign the id by hand." >&2
    exit 1
  }
  echo "    created policy …${policy_id: -6}"

  # Step 3 — assignment. The server's materializability check runs here (T1): a
  # policy that created cleanly can still be rejected by set-default, whose non-zero
  # exit (set -e) is the only assignment signal this CLI surface gives.
  echo "==> assigning as organization default"
  "${ONA_BIN}" organization security-policy set-default "${policy_id}"

  # Step 4 — presence check. This proves the policy still exists after set-default;
  # it does NOT prove the assignment. `security-policy list` shows inactive policies
  # too, and no `ona` verb reads the org default. The assignment itself is proven by
  # GetOrganizationPolicies.securityPolicyId — api pack hth-ona-2.01 reads it.
  verify_default "${policy_id}"

  # T2: nothing above touches a running environment.
  echo "NOTE: restart environments to pick this up — a running environment keeps"
  echo "      the policy it had at its last start."
}

# Presence check (not an assignment proof — see Step 4). `list -o json` field
# spellings are not published, so match the id anywhere in the document.
verify_default() {
  local policy_id="$1" listing
  listing="$("${ONA_BIN}" organization security-policy list -o json)"
  if printf '%s' "${listing}" | jq -e --arg id "${policy_id}" \
       '[.. | strings] | any(. == $id)' >/dev/null; then
    echo "PRESENT: policy …${policy_id: -6} is in the organization policy list; confirm the"
    echo "         default assignment with api pack hth-ona-2.01 (GetOrganizationPolicies.securityPolicyId)."
    return 0
  fi
  echo "FINDING: policy …${policy_id: -6} not visible in 'security-policy list'." >&2
  exit 1
}
# HTH Guide Excerpt: end cli-veto-policy-apply

# HTH Guide Excerpt: begin cli-veto-policy-clear
# Clear the default assignment. Read T3 before using this: it removes EVERY
# control in that SecurityPolicy from newly created environments, not only the
# executable rules. The documented rollback for Veto Exec alone is to set each
# rule back to `effect: EFFECT_AUDIT` and run `update` instead.
# Guarded by a literal CONFIRM argument so it cannot be reached by a typo.
clear_default() {
  [ "${1:-}" = "CONFIRM" ] || {
    echo "REFUSING: --clear removes the entire default SecurityPolicy assignment" >&2
    echo "          (all controls, not just executables) from newly created" >&2
    echo "          environments. Re-run with: $0 --clear CONFIRM" >&2
    exit 2
  }
  "${ONA_BIN}" organization security-policy set-default --clear
  echo "Default SecurityPolicy assignment cleared."
  echo "NOTE: already-running environments are unchanged; restart them to drop it."
}
# HTH Guide Excerpt: end cli-veto-policy-clear

main() {
  require_cli
  authenticate
  case "${1:-apply}" in
    apply)   apply_policy "${POLICY_FILE}" ;;
    --clear) clear_default "${2:-}" ;;
    *) echo "usage: $0 [apply] | --clear CONFIRM" >&2; exit 2 ;;
  esac
}

main "$@"
