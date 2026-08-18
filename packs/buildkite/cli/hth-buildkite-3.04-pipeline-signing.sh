#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.4: Enable Pipeline Signing and Verification
#   — SIGNING half (key generation + signing pipeline steps)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 16.9 | NIST 800-53 SI-7
# Source: https://howtoharden.com/guides/buildkite/#34-enable-pipeline-signing-and-verification
#
# PAIRS WITH: packs/buildkite/config/hth-buildkite-3.04-verification.sh
# Signing alone changes nothing. Steps get a `signature` field that no agent
# reads until a verification key is installed on the executing agents. Ship both.
#
# AGENT MAJOR VERSION: this pack targets buildkite-agent **v3** (current major;
# latest release at authoring was v3.137.0 — there is no released v4). All flags,
# env vars and defaults below were read from docs/agent/v3/* and cross-checked
# against the agent source, so there is no v3/v4 divergence to document yet.
#
# AUTHORING STATUS: DRIFT-CHECKED-ONLY.
# `buildkite-agent` is not installed in the authoring environment, so none of
# these commands were executed here. Every flag spelling, env var and default was
# verified against the vendor docs (buildkite.com/docs/agent/v3/signed-pipelines,
# .../cli-tool, .../configuration) AND against github.com/buildkite/agent at main
# (clicommand/tool_sign.go, clicommand/tool_keygen.go), read 2026-08-18.
#
# -----------------------------------------------------------------------------
# GUIDE ERROR THIS PACK CORRECTS
# -----------------------------------------------------------------------------
# Guide 3.4 Step 1 presents `--jwks-file` / `--jwks-key-id` as *agent* flags.
# They are not. They are flags on `buildkite-agent tool sign`. The agent's own
# configuration keys are DIFFERENT identifiers:
#
#   tool sign flag      agent config key         agent env var
#   --------------      ----------------         -------------
#   --jwks-file         signing-jwks-file        BUILDKITE_AGENT_SIGNING_JWKS_FILE
#   --jwks-key-id       signing-jwks-key-id      BUILDKITE_AGENT_SIGNING_JWKS_KEY_ID
#   (n/a)               verification-jwks-file   BUILDKITE_AGENT_VERIFICATION_JWKS_FILE
#
# And `tool sign` reads its OWN env vars, which are not the agent's:
#   --jwks-file    <- $BUILDKITE_AGENT_JWKS_FILE     (NOT ..._SIGNING_JWKS_FILE)
#   --jwks-key-id  <- $BUILDKITE_AGENT_JWKS_KEY_ID
# Exporting the agent-config env var and expecting `tool sign` to pick it up is a
# silent no-op: the tool falls through to LoadKey("") and errors on an empty path.
#
# -----------------------------------------------------------------------------
# NON-OBVIOUS TRAPS (all read from clicommand/tool_sign.go)
# -----------------------------------------------------------------------------
# T1  --graphql-token SILENTLY DISCARDS your local file. Vendor's own flag text:
#     "Both 'repo' and 'pipeline-file' will be ignored in preference of values
#     from the GraphQL API if the token in provided." Passing a token AND a local
#     .yml signs whatever is stored server-side, not the file you edited.
# T2  Offline signing (no --graphql-token) HARD-REQUIRES --repo. Without it the
#     tool returns ErrUseGraphQL. The repo URL is bound into the signature.
# T3  Offline signing REJECTS any pipeline containing `$` interpolations —
#     validateNoInterpolations() fails the run and names each offending
#     identifier. Interpolation is only supported on dynamic upload, so a
#     pipeline that signs cleanly in CI may refuse to sign statically.
# T4  --update PROMPTS on a TTY and BLOCKS FOREVER in CI without --no-confirm.
#     promptConfirm() returns early only when NoConfirm is set.
# T5  KEY BACKEND PRECEDENCE IS SILENT: AWS KMS wins over GCP KMS wins over
#     --jwks-file. Set --signing-aws-kms-key and your --jwks-file is ignored
#     with no warning — you will sign with a key you did not intend.
# T6  --debug-signing "can potentially leak secrets to the logs as it prints each
#     step in full before signing" (vendor's words). This pack refuses to enable
#     it unless HTH_ALLOW_DEBUG_SIGNING=1 is set explicitly.
# T7  keygen writes BOTH a private and a public JWKS. The PRIVATE set goes only
#     to signers; the PUBLIC set is what executing agents get as
#     verification-jwks-file. Shipping the private set as the verification file
#     hands every agent host the ability to forge pipelines. assert_public_only()
#     below fails closed on that mistake.
# T8  Without --private-jwks-file/--public-jwks-file, keygen writes files named
#     from the key id into the CWD — easy to commit by accident. This pack
#     refuses to generate into a path git does not ignore.
#
# -----------------------------------------------------------------------------
# GCP KMS — UNRESOLVED, DO NOT PROPAGATE EITHER CLAIM
# -----------------------------------------------------------------------------
# The guide claims GCP KMS support. Status as of 2026-08-18:
#   * `--signing-gcp-kms-key` IS a real flag on `tool sign`, and the action body
#     constructs a real gcpsigner.NewKMS signer, so the signing side is wired.
#   * `signing-gcp-kms-key` IS in the agent configuration reference.
#   * BUT the vendor's signed-pipelines walkthrough documents **AWS KMS only**.
#     There is no documented end-to-end GCP flow, including the agent-side
#     verification half.
# This pack therefore implements the JWKS and AWS KMS paths, which are documented
# end to end, and does not assert that the GCP path works. Verify it yourself
# before relying on it.
#
# Requires: buildkite-agent v3 on PATH, jq, git (for the ignore check).
# =============================================================================

set -euo pipefail

BK_AGENT="${BK_AGENT:-buildkite-agent}"
KEY_ID="${BUILDKITE_SIGNING_KEY_ID:-hth-pipeline-signing}"
KEY_ALG="${BUILDKITE_SIGNING_ALG:-EdDSA}"
KEY_DIR="${BUILDKITE_SIGNING_KEY_DIR:-./buildkite-signing-keys}"
PRIVATE_JWKS="${BUILDKITE_SIGNING_PRIVATE_JWKS:-${KEY_DIR}/${KEY_ID}-private.json}"
PUBLIC_JWKS="${BUILDKITE_SIGNING_PUBLIC_JWKS:-${KEY_DIR}/${KEY_ID}-public.json}"

# HTH Guide Excerpt: begin cli-signing-keygen
# Generate the signing key pair. EdDSA is the agent default; PS512 and ES512 are
# the only other accepted algorithms (jwkutil.ValidSigningAlgorithms).
require_agent() {
  command -v "${BK_AGENT}" >/dev/null 2>&1 || {
    echo "FATAL: '${BK_AGENT}' not on PATH. Install buildkite-agent v3." >&2
    exit 127
  }
  command -v jq >/dev/null 2>&1 || { echo "FATAL: jq required." >&2; exit 127; }
}

# T8: never write private key material into a path git will track.
assert_ignored() {
  local path="$1"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git check-ignore -q "${path}" && return 0
  echo "REFUSING: '${path}' is not git-ignored. Add '${KEY_DIR}/' to" >&2
  echo "          .gitignore before generating signing keys." >&2
  exit 3
}

# T7: a JWK carrying the private parameter 'd' is private material for every
# algorithm the agent accepts (Ed25519, EC, RSA). A verification keyset must
# never contain one.
assert_public_only() {
  local path="$1"
  jq -e 'if (.keys | type) != "array" then false
         else ([.keys[] | has("d")] | any | not) end' "${path}" >/dev/null || {
    echo "FATAL: '${path}' contains private key material (JWK parameter 'd')." >&2
    echo "       Never distribute this file as verification-jwks-file." >&2
    exit 4
  }
}

keygen() {
  require_agent
  case "${KEY_ALG}" in
    EdDSA|PS512|ES512) ;;
    *) echo "FATAL: --alg must be EdDSA, PS512 or ES512 (got '${KEY_ALG}')." >&2; exit 2 ;;
  esac

  mkdir -p "${KEY_DIR}"
  chmod 700 "${KEY_DIR}"
  assert_ignored "${PRIVATE_JWKS}"

  "${BK_AGENT}" tool keygen \
    --alg "${KEY_ALG}" \
    --key-id "${KEY_ID}" \
    --private-jwks-file "${PRIVATE_JWKS}" \
    --public-jwks-file "${PUBLIC_JWKS}"

  chmod 600 "${PRIVATE_JWKS}"
  chmod 644 "${PUBLIC_JWKS}"
  assert_public_only "${PUBLIC_JWKS}"

  echo "private (signers only, never distribute): ${PRIVATE_JWKS}"
  echo "public  (-> agent verification-jwks-file): ${PUBLIC_JWKS}"
}
# HTH Guide Excerpt: end cli-signing-keygen

# HTH Guide Excerpt: begin cli-sign-pipeline
# Sign pipeline steps with the self-managed JWKS private key.
#
# Two distinct modes, and the flags are NOT interchangeable:
#   offline  - signs the local YAML file. Requires --repo (T2). Rejects any
#              pipeline containing $ interpolations (T3). Prints the signed
#              pipeline to stdout; nothing is uploaded.
#   publish  - passes --graphql-token, so the tool downloads the pipeline and
#              repo URL from Buildkite and IGNORES the local file entirely (T1),
#              then writes the signed definition back with --update.
sign_offline() {
  local pipeline_file="${1:?path to pipeline YAML required}"
  require_agent
  : "${BUILDKITE_REPO:?set BUILDKITE_REPO to the pipeline repository URL (bound into the signature)}"
  [ -r "${PRIVATE_JWKS}" ] || { echo "FATAL: no signing key at ${PRIVATE_JWKS}; run keygen." >&2; exit 5; }

  "${BK_AGENT}" tool sign \
    --jwks-file "${PRIVATE_JWKS}" \
    --jwks-key-id "${KEY_ID}" \
    --repo "${BUILDKITE_REPO}" \
    "${pipeline_file}"
}

sign_and_publish() {
  require_agent
  : "${BUILDKITE_GRAPHQL_TOKEN:?set BUILDKITE_GRAPHQL_TOKEN (GraphQL token with write_pipelines)}"
  : "${BUILDKITE_ORGANIZATION_SLUG:?set BUILDKITE_ORGANIZATION_SLUG}"
  : "${BUILDKITE_PIPELINE_SLUG:?set BUILDKITE_PIPELINE_SLUG}"
  [ -r "${PRIVATE_JWKS}" ] || { echo "FATAL: no signing key at ${PRIVATE_JWKS}; run keygen." >&2; exit 5; }

  local -a args=(
    tool sign
    --graphql-token "${BUILDKITE_GRAPHQL_TOKEN}"
    --jwks-file "${PRIVATE_JWKS}"
    --jwks-key-id "${KEY_ID}"
    --organization-slug "${BUILDKITE_ORGANIZATION_SLUG}"
    --pipeline-slug "${BUILDKITE_PIPELINE_SLUG}"
    --update
  )
  # T4: --update prompts on a TTY. In CI there is no TTY to answer it.
  [ -t 0 ] || args+=( --no-confirm )
  # T6: opt-in only; this flag prints every step in full and can leak secrets.
  [ "${HTH_ALLOW_DEBUG_SIGNING:-0}" = "1" ] && args+=( --debug-signing )

  "${BK_AGENT}" "${args[@]}"
}
# HTH Guide Excerpt: end cli-sign-pipeline

# HTH Guide Excerpt: begin cli-sign-aws-kms
# AWS KMS backend: the private key never lands on the signing host.
# T5: setting --signing-aws-kms-key makes --jwks-file dead weight — the agent
# selects AWS KMS first and never reads the file. Pass one backend, not both.
# Agents verifying these signatures configure signing-aws-kms-key (the same key
# serves both directions for the KMS backend), not verification-jwks-file.
sign_with_aws_kms() {
  require_agent
  : "${BUILDKITE_SIGNING_AWS_KMS_KEY:?set BUILDKITE_SIGNING_AWS_KMS_KEY (KMS key id or alias)}"
  : "${BUILDKITE_GRAPHQL_TOKEN:?set BUILDKITE_GRAPHQL_TOKEN (GraphQL token with write_pipelines)}"
  : "${BUILDKITE_ORGANIZATION_SLUG:?set BUILDKITE_ORGANIZATION_SLUG}"
  : "${BUILDKITE_PIPELINE_SLUG:?set BUILDKITE_PIPELINE_SLUG}"

  local -a args=(
    tool sign
    --graphql-token "${BUILDKITE_GRAPHQL_TOKEN}"
    --signing-aws-kms-key "${BUILDKITE_SIGNING_AWS_KMS_KEY}"
    --organization-slug "${BUILDKITE_ORGANIZATION_SLUG}"
    --pipeline-slug "${BUILDKITE_PIPELINE_SLUG}"
    --update
  )
  [ -t 0 ] || args+=( --no-confirm )

  # Standard AWS SDK credential resolution applies; prefer an instance/OIDC role
  # over static keys so the signing identity is short-lived.
  "${BK_AGENT}" "${args[@]}"
}
# HTH Guide Excerpt: end cli-sign-aws-kms

case "${1:-help}" in
  keygen)   keygen ;;
  sign)     sign_offline "${2:?usage: $0 sign <pipeline.yml>}" ;;
  publish)  sign_and_publish ;;
  kms)      sign_with_aws_kms ;;
  help|*)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-3.04-pipeline-signing.sh keygen           generate JWKS key pair
  hth-buildkite-3.04-pipeline-signing.sh sign <file.yml>  sign locally (needs BUILDKITE_REPO)
  hth-buildkite-3.04-pipeline-signing.sh publish          sign server-side copy and --update
  hth-buildkite-3.04-pipeline-signing.sh kms              sign via AWS KMS and --update

Distribute the PUBLIC keyset to executing agents as verification-jwks-file — see
packs/buildkite/config/hth-buildkite-3.04-verification.sh. Signing without that
step leaves every agent executing unverified jobs.
USAGE
    exit 2 ;;
esac
