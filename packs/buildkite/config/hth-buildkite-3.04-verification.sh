#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.4: Enable Pipeline Signing and Verification
#   — VERIFICATION half (agent-side buildkite-agent.cfg)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 16.9 | NIST 800-53 SI-7
# Source: https://howtoharden.com/guides/buildkite/#34-enable-pipeline-signing-and-verification
#
# PAIRS WITH: packs/buildkite/cli/hth-buildkite-3.04-pipeline-signing.sh
# That pack mints the keys and signs the steps. This one installs the public
# keyset on every executing agent and makes an unverifiable job fail the build.
# Neither pack is a control on its own.
#
# AGENT MAJOR VERSION: targets buildkite-agent **v3** (current major; latest
# release at authoring v3.137.0 — no released v4). Config keys, env vars and
# defaults read from docs/agent/v3/configuration and from the agent source.
#
# AUTHORING STATUS: DRIFT-CHECKED-ONLY.
# `buildkite-agent` is not installed in the authoring environment, so nothing
# below was executed here. Every key name, env var and default was verified
# against buildkite.com/docs/agent/v3/configuration AND against
# github.com/buildkite/agent at main (clicommand/agent_start.go lines 682-718,
# agent/run_job.go lines 133-166), read 2026-08-18.
#
# -----------------------------------------------------------------------------
# ⚠️ THE REASON THIS PACK EXISTS: verification-failure-behavior ALONE IS THEATER
# -----------------------------------------------------------------------------
# From agent/run_job.go, verbatim structure:
#
#   L133   if r.conf.JWKS == nil && job.Step.Signature != nil {   // no key, signed job
#              ... verificationFailureLogs(...); if behavior == block { reject }
#          }
#   L146   if r.conf.JWKS != nil {                                 // key present
#              switch err := r.verifyJob(ctx, r.conf.JWKS); {
#              case errors.Is(err, ErrNoSignature) || invalidSignature:
#                  ... if behavior == block { reject }
#              case err != nil:  reject (always fatal)
#              default:          "Successfully verified job"
#          }
#
# Read the gap between those two blocks. When `verification-jwks-file` is unset
# (JWKS == nil) AND the incoming job carries no signature, the L133 condition is
# false and the L146 condition is false. NEITHER branch executes. The job runs.
# `verification-failure-behavior` is never consulted on that path — setting it to
# `block` on an agent with no verification key blocks exactly nothing, and the
# build output looks completely normal.
#
# An unsigned job is precisely the attack this control exists to stop. So:
#   verification-failure-behavior WITHOUT verification-jwks-file = no control.
# audit_verification() below fails closed on exactly that combination.
#
# -----------------------------------------------------------------------------
# ⚠️ THE GUIDE'S ROLLOUT NARRATIVE RUNS BACKWARDS
# -----------------------------------------------------------------------------
# Guide 3.4 Step 2 says to "roll out verification in a warning posture first,
# then move to rejecting unsigned steps." The destination is already the default:
# agent_start.go declares verification-failure-behavior with
# `Value: agent.VerificationBehaviourBlock`. You do not climb to `block` — you
# ship it, and if the fleet is not ready you deliberately LOOSEN to `warn`, then
# remove the override to get back to the secure default.
#
# Correct sequence (what apply_warn/apply_block below implement):
#   1. Install the PUBLIC keyset as verification-jwks-file on every executing
#      agent. Until this exists there is nothing to warn about (see above).
#   2. TEMPORARILY set verification-failure-behavior=warn. This is a downgrade
#      from the default and should carry an expiry date.
#   3. Confirm every uploader is signing (logs read "Successfully verified job").
#   4. Remove the override — back to the default `block`.
#
# -----------------------------------------------------------------------------
# NON-OBVIOUS TRAPS
# -----------------------------------------------------------------------------
# T1  THE ENV VAR DOES NOT MATCH THE CONFIG KEY.
#       verification-jwks-file          -> BUILDKITE_AGENT_VERIFICATION_JWKS_FILE
#       verification-failure-behavior   -> BUILDKITE_AGENT_JOB_VERIFICATION_NO_SIGNATURE_BEHAVIOR
#     The obvious guess (BUILDKITE_AGENT_VERIFICATION_FAILURE_BEHAVIOR) is not
#     bound to anything and is silently ignored — leaving you on the default.
#     For containerised agents this is the single easiest way to think you
#     configured the control when you did not.
# T2  This is the SIGNING key's public half, not the signing key. A private JWKS
#     installed here gives every agent host the ability to forge pipelines.
#     assert_public_only() rejects any keyset containing the JWK parameter 'd'.
# T3  AWS/GCP KMS backends do NOT use verification-jwks-file. Those agents set
#     signing-aws-kms-key (the same key both signs and verifies). Configuring
#     both backends at once is a misconfiguration, not defence in depth.
# T4  The agent reads its config file once at start. Every function here restarts
#     nothing — apply the change, then restart the agent, then re-audit.
# T5  Verification is enforced on the agent host, which means it is only as
#     trustworthy as that host. Anyone who can edit buildkite-agent.cfg can
#     delete verification-jwks-file. Pair with control 3.3 (agent host hardening)
#     and file permissions below; root-owned 0644 config, 0644 keyset.
#
# Requires: jq, and write access to the agent config. Run on the AGENT host.
# =============================================================================

set -euo pipefail

AGENT_CFG="${BUILDKITE_AGENT_CONFIG:-/etc/buildkite-agent/buildkite-agent.cfg}"
VERIFICATION_JWKS="${BUILDKITE_VERIFICATION_JWKS:-/etc/buildkite-agent/verification-jwks.json}"

# HTH Guide Excerpt: begin config-verification-keys
# Install the public keyset and pin the agent to the secure default.
# Run on every agent that EXECUTES jobs, not just the ones that upload pipelines.

# T2: reject private key material. 'd' is the private parameter for Ed25519,
# EC and RSA keys alike, so this one test covers EdDSA, ES512 and PS512.
assert_public_only() {
  local path="$1"
  [ -r "${path}" ] || { echo "FATAL: keyset '${path}' not readable." >&2; exit 4; }
  jq -e 'if (.keys | type) != "array" then false
         else ([.keys[] | has("d")] | any | not) end' "${path}" >/dev/null || {
    echo "FATAL: '${path}' contains PRIVATE key material (JWK parameter 'd')." >&2
    echo "       Install the --public-jwks-file output here, never the private one." >&2
    exit 4
  }
}

# Idempotent upsert of a single `key=value` line in buildkite-agent.cfg.
set_cfg() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "${AGENT_CFG}"; then
    sed -E "s|^[[:space:]]*${key}[[:space:]]*=.*$|${key}=${value}|" "${AGENT_CFG}" >"${tmp}"
  else
    cat "${AGENT_CFG}" >"${tmp}"
    printf '%s=%s\n' "${key}" "${value}" >>"${tmp}"
  fi
  cat "${tmp}" >"${AGENT_CFG}"
  rm -f "${tmp}"
}

unset_cfg() {
  local key="$1" tmp
  tmp="$(mktemp)"
  grep -vE "^[[:space:]]*${key}[[:space:]]*=" "${AGENT_CFG}" >"${tmp}" || true
  cat "${tmp}" >"${AGENT_CFG}"
  rm -f "${tmp}"
}

# Step 1 + 4: the end state. verification-failure-behavior=block is written
# explicitly so the posture is auditable on disk rather than inherited silently.
apply_block() {
  [ -w "${AGENT_CFG}" ] || { echo "FATAL: cannot write ${AGENT_CFG} (run as root)." >&2; exit 5; }
  assert_public_only "${VERIFICATION_JWKS}"
  chmod 0644 "${VERIFICATION_JWKS}"

  set_cfg "verification-jwks-file" "${VERIFICATION_JWKS}"
  set_cfg "verification-failure-behavior" "block"

  echo "Applied. Restart the agent, then run: $0 audit"
}

# Step 2: the DELIBERATE LOOSENING for a staged rollout. This is strictly less
# secure than the default. The keyset is still installed first — without it the
# warn posture reports nothing at all on unsigned jobs.
apply_warn() {
  [ -w "${AGENT_CFG}" ] || { echo "FATAL: cannot write ${AGENT_CFG} (run as root)." >&2; exit 5; }
  assert_public_only "${VERIFICATION_JWKS}"

  set_cfg "verification-jwks-file" "${VERIFICATION_JWKS}"
  set_cfg "verification-failure-behavior" "warn"

  echo "WARNING: this agent now EXECUTES jobs that fail signature verification."
  echo "         This is a temporary rollout state. Run '$0 apply-block' to restore"
  echo "         the vendor default once every uploader is signing."
}

# Container / env-var equivalent. T1: note the two env var names do not follow
# the same pattern as each other, and neither matches its config key exactly.
print_env_equivalent() {
  cat <<ENVEOF
# buildkite-agent v3 — verification via environment (containers, systemd units)
BUILDKITE_AGENT_VERIFICATION_JWKS_FILE=${VERIFICATION_JWKS}
BUILDKITE_AGENT_JOB_VERIFICATION_NO_SIGNATURE_BEHAVIOR=block
# NOTE: BUILDKITE_AGENT_VERIFICATION_FAILURE_BEHAVIOR is NOT a real variable.
ENVEOF
}
# HTH Guide Excerpt: end config-verification-keys

# HTH Guide Excerpt: begin config-verification-audit
# Prove the control is real. Fails closed on the security-theater combination:
# a verification-failure-behavior with no verification key to enforce it with.
audit_verification() {
  local jwks behavior rc=0
  jwks="$(sed -nE 's|^[[:space:]]*verification-jwks-file[[:space:]]*=[[:space:]]*(.*)$|\1|p' "${AGENT_CFG}" | tail -1)"
  behavior="$(sed -nE 's|^[[:space:]]*verification-failure-behavior[[:space:]]*=[[:space:]]*(.*)$|\1|p' "${AGENT_CFG}" | tail -1)"

  # The agent default is block, so an absent key is NOT an absent posture.
  [ -n "${behavior}" ] || behavior="block (agent default)"

  echo "config file                   : ${AGENT_CFG}"
  echo "verification-jwks-file        : ${jwks:-<unset>}"
  echo "verification-failure-behavior : ${behavior}"

  if [ -z "${jwks}" ]; then
    echo "FAIL: no verification key configured. run_job.go only verifies when" >&2
    echo "      r.conf.JWKS != nil — an UNSIGNED job runs here regardless of" >&2
    echo "      verification-failure-behavior. This agent enforces nothing." >&2
    rc=1
  else
    if [ ! -r "${jwks}" ]; then
      echo "FAIL: verification-jwks-file '${jwks}' is missing or unreadable." >&2
      rc=1
    else
      assert_public_only "${jwks}"
      echo "PASS: verification key present and contains no private material."
    fi
  fi

  # The behavior verdict is only meaningful when a key exists. Reporting
  # "unverifiable jobs are rejected" on a keyless agent would restate the very
  # false assurance this pack exists to remove.
  case "${behavior}" in
    block*)
      if [ -n "${jwks}" ]; then
        echo "PASS: unverifiable jobs are rejected."
      else
        echo "FAIL: 'block' is INERT here — with no key, unsigned jobs bypass" >&2
        echo "      both branches of run_job.go and execute." >&2
      fi ;;
    warn)   echo "WARN: unverifiable jobs EXECUTE. Rollout state only — restore 'block'." ;;
    *)      echo "FAIL: unrecognised behavior '${behavior}' (expected warn|block)." >&2; rc=1 ;;
  esac

  # T3: KMS-backed agents verify with the KMS key, not a JWKS file.
  if grep -qE '^[[:space:]]*signing-(aws|gcp)-kms-key[[:space:]]*=' "${AGENT_CFG}" && [ -n "${jwks}" ]; then
    echo "FAIL: both a KMS key and verification-jwks-file are configured. Pick one" >&2
    echo "      backend — this is a misconfiguration, not defence in depth." >&2
    rc=1
  fi

  return "${rc}"
}
# HTH Guide Excerpt: end config-verification-audit

case "${1:-audit}" in
  apply-block) apply_block ;;
  apply-warn)  apply_warn ;;
  env)         print_env_equivalent ;;
  audit)       audit_verification ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-3.04-verification.sh apply-block   install keyset + enforce (end state)
  hth-buildkite-3.04-verification.sh apply-warn    install keyset + temporary warn-only
  hth-buildkite-3.04-verification.sh env           print container env-var equivalent
  hth-buildkite-3.04-verification.sh audit         prove enforcement is real (exit 1 on fail)

Restart buildkite-agent after apply-*; the config is read once at start.
USAGE
    exit 2 ;;
esac
