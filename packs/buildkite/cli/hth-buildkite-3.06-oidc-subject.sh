#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.6: Use OIDC Instead of Static Cloud Credentials
#   — SUBJECT half (`buildkite-agent oidc request-token --subject-claim`
#     + the agent-side `environment` hook that scopes it)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.4 | NIST 800-53 IA-5, IA-9
# Source: https://howtoharden.com/guides/buildkite/#36-use-oidc-instead-of-static-cloud-credentials
#
# PAIRS WITH: packs/buildkite/config/hth-buildkite-3.06-oidc-secrets.yml
# That pack is the pipeline-author half (which step exchanges a token for which
# role). This pack is the AGENT-OPERATOR half: it decides what the token's `sub`
# claim says, from a file the pipeline's repository cannot edit. Ship both.
#
# AGENT MAJOR VERSION: v3 and v4 are identical for this command. Verified by
# diffing clicommand/oidc_request_token.go at tag v3.137.0 (module
# github.com/buildkite/agent/v3) against branch main (module .../agent/v4), read
# 2026-08-18 — same eight flags, same env var sources, same validation, only the
# urfave/cli generation differs.
#
# MINIMUM AGENT VERSION: v3.121.0, and it is `--subject-claim` ALONE that sets it.
# Reading clicommand/oidc_request_token.go tag by tag: at v3.120.0 the registered
# flags are audience, lifetime, job, claim, aws-session-tag, skip-redaction,
# format — `--claim` is already there — and v3.121.0 adds `subject-claim` to that
# list. So `--claim` is NOT a v3.121.0 feature and carries no floor of its own;
# only the subject half of this pack does. On an older agent the new flag is not
# "ignored" — urfave/cli errors on an unknown flag and the token request fails, so
# a fleet mid-upgrade fails the build rather than silently minting a
# default-subject token. Related: OIDC tokens are auto-redacted from build logs
# only from v3.104.0.
#
# AUTHORING STATUS: DRIFT-CHECKED-ONLY.
# `buildkite-agent` is not on PATH in the authoring environment, so NONE of these
# commands were executed here. Every flag, env var, default and claim name was
# verified against github.com/buildkite/agent clicommand/oidc_request_token.go at
# BOTH v3.137.0 and main, and against buildkite/docs at main
# (pages/agent/cli/reference/oidc.md), read 2026-08-18.
#
# -----------------------------------------------------------------------------
# ⚠️ "RESTRICT THE SUBJECT CLAIM" IS HALF BACKWARDS. READ THIS FIRST.
# -----------------------------------------------------------------------------
# --subject-claim does not narrow trust. It REPLACES a compound subject with a
# single identifier, and whether that is narrower or wider depends entirely on
# which identifier you pick.
#
# The DEFAULT subject (verified, docs pages/agent/cli/reference/oidc.md) is:
#
#   organization:ORG_SLUG:pipeline:PIPELINE_SLUG:ref:REF:commit:SHA:step:STEP_KEY
#
# That is the MOST GRANULAR subject Buildkite will issue — org, pipeline, branch
# or tag, commit and step, all in one string a cloud policy can prefix-match. It
# is also entirely composed of MUTABLE values. Rename a pipeline and every trust
# policy keyed on the old slug goes dead. Worse in the other direction: DELETE a
# pipeline and CREATE a new one that reuses the slug, and the new pipeline — new
# owners, new repository, new steps — inherits the old one's cloud trust. Nothing
# in the token distinguishes them, because a slug is a name, not an identity.
#
# --subject-claim buys IMMUTABILITY against that, and pays for it in granularity:
#
#   --subject-claim pipeline_id   sub = the pipeline UUID.
#                                 NARROWER on identity (a recreated pipeline gets a
#                                 new UUID, so it inherits nothing) but WIDER on
#                                 scope: ref, commit and step are GONE from the
#                                 subject. Every branch of that pipeline now
#                                 presents the same sub. If your policy relied on
#                                 the ref segment, you have just opened it up.
#                                 Restore the lost granularity with additional
#                                 conditions on build_branch / step_key, or the
#                                 net change is a LOOSENING.
#
#   --subject-claim cluster_id    sub = the cluster UUID. EVERY pipeline that can
#   --subject-claim queue_id      run on that cluster/queue presents an IDENTICAL
#                                 subject. This is a BROADENING. It is the right
#                                 answer only when the cluster IS the trust
#                                 boundary (control 3.2) and you accept that any
#                                 pipeline admitted to it can assume the role.
#
#   --subject-claim organization_id
#                                 sub = the org UUID. Every pipeline in the entire
#                                 organization presents the same subject. THIS IS
#                                 THE WIDEST SUBJECT THE COMMAND CAN PRODUCE. It
#                                 is not a hardening step and this pack will not
#                                 present it as one. Use it only when the relying
#                                 party demands an exact-match subject AND you
#                                 carry the real scoping in other claims — and say
#                                 so out loud in the trust policy's comment.
#
#   --subject-claim build_id      sub = a value that is DIFFERENT ON EVERY BUILD.
#   --subject-claim job_id        No static cloud policy can match these on `sub`.
#   --subject-claim agent_id      agent_id in particular ties trust to a machine,
#                                 not to code, which is usually the wrong axis.
#
# Full accepted set (docs, "Custom subject claims"): organization_id, pipeline_id,
# cluster_id, queue_id, build_id, job_id, agent_id. Slugs and branch names are
# REFUSED by design — "renaming them would silently break trust relationships."
# assert_subject_claim() below enforces exactly that list and refuses the two
# broadening values unless the operator opts in explicitly.
#
# The honest summary: pipeline_id is the usual right answer, it is a MUTABILITY
# fix and not a SCOPE fix, and it must be accompanied by branch/step conditions in
# the relying party's policy or you have traded down.
#
# -----------------------------------------------------------------------------
# NON-OBVIOUS TRAPS
# -----------------------------------------------------------------------------
# T1  IT TAKES A CLAIM NAME, NOT A UUID. `--subject-claim pipeline_id` is correct;
#     `--subject-claim 0184990a-4782-42b5-afc1-16715b10b1l0` is not. The literal
#     string you pass is the KEY whose VALUE becomes the subject. Passing a UUID
#     asks Buildkite for a claim that does not exist.
# T2  THE CLOUD PLUGINS NEVER PASS THIS FLAG. Verified in lib/plugin.bash of both
#     aws-assume-role-with-web-identity v1.7.0 and
#     gcp-workload-identity-federation v1.6.0: neither ever appends
#     --subject-claim. The ONLY way to change the subject of the token those
#     plugins mint is the environment variable BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM,
#     which the flag reads (Sources: cli.EnvVars(...)). That is what the
#     `environment` hook region below exists to set.
# T3  ...WHICH MEANS pipeline.yml CAN SET IT TOO, AND MUST NOT. Buildkite
#     pipelines can define `env:`. If the subject is chosen in the repository,
#     anyone who can merge a pull request can widen their own token's subject to
#     organization_id and present the same `sub` as a more privileged pipeline.
#     Set it in the AGENT hook — off-repo, operator-owned — and have the hook
#     OVERWRITE any inherited value rather than defer to it. install_environment_hook()
#     writes an unconditional assignment for exactly this reason.
# T4  --subject-claim AUTO-INCLUDES THE CLAIM. Docs: "When --subject-claim is used,
#     the specified claim is automatically included in the token. You don't need
#     to also pass it with --claim." Passing both is harmless but signals the
#     author did not read what the flag does.
# T5  THE FLAG IS --claim, SINGULAR. The docs' prose says "adding `--claims`" while
#     every worked example on the same page uses `--claim`, and the source
#     registers Name: "claim" with no alias. `--claims` is an unknown flag and
#     errors out. Multiple values go in ONE flag, comma separated:
#     --claim "organization_id,pipeline_id".
# T5b --claim TAKES OPTIONAL CLAIMS ONLY, AND MOST SCOPING CLAIMS ARE NOT OPTIONAL.
#     The docs split the claim table in two. Everything above "### Optional claims"
#     — organization_slug, pipeline_slug, build_number, build_branch, build_tag,
#     build_commit, step_key, job_id, agent_id, build_source, runner_environment —
#     is ALREADY in every token; the vendor's own "Example token contents" prints
#     all of them for a request that passed no --claim at all. The `--claim` flag
#     ADDS from the optional table and from nothing else:
#         organization_id  pipeline_id  build_id
#         cluster_id  cluster_name  queue_id  queue_key  agent_tag:NAME
#     So `--claim "build_branch,step_key"` asks the API to add two claims the token
#     already carries. It reads as scoping and buys nothing. What the API does with
#     an unaddable name is UNVERIFIED and cannot be settled from the client: the
#     agent does no validation of its own — oidc_request_token.go carries a literal
#     `// TODO: enumerate possible values` above the flag and forwards whatever it
#     is given — so the outcome is somewhere between silently ignored and a failed
#     token request, decided server-side. Not knowing which, in the command that
#     mints a cloud credential, is reason enough not to send one. Branch and step
#     conditions belong in the RELYING PARTY's policy, keyed on the default claims
#     that are already present.
#     assert_optional_claims() below refuses any name outside the optional table.
#     NOTE the asymmetry with --aws-session-tag, three lines of argv away: session
#     tags may carry "any of the supported claims" (docs, "AWS session tags"), and
#     the vendor's own example tags organization_slug — a DEFAULT claim. Mixing is
#     correct there and wrong here, which is exactly why this trap exists.
# T6  DEFAULT LIFETIME IS 5 MINUTES, AND --lifetime 0 MEANS "DEFAULT", NOT
#     "FOREVER". `exp` defaults to 5 minutes out; --lifetime must be a
#     non-negative integer and 0 is explicitly treated as unset. Do not read a
#     literal 0 in a plugin's argv as an unbounded token.
# T7  DEFAULT AUDIENCE IS https://buildkite.com/ORG_SLUG — a URL, and derived from
#     a MUTABLE slug. Always pass --audience explicitly for a real relying party
#     (AWS wants sts.amazonaws.com; Entra ID wants api://AzureADTokenExchange).
# T8  --skip-redaction PRINTS THE TOKEN TO THE BUILD LOG. Redaction is on by
#     default from v3.104.0 and is implemented through the Job API over a Unix
#     domain socket; where that socket is unavailable the command FAILS rather
#     than leak, and --skip-redaction is the documented override. Treat any
#     pipeline carrying that flag, or
#     BUILDKITE_AGENT_OIDC_REQUEST_TOKEN_SKIP_TOKEN_REDACTION, as a finding.
#     audit_oidc_usage() greps for both.
# T9  A CAPTURED TOKEN IS A BEARER CREDENTIAL FOR ITS WHOLE LIFETIME. `sub` binds
#     it to a pipeline, not to a process. `--lifetime` is the only thing limiting
#     replay, so keep it at or below the credential it buys (900s in the paired
#     pipeline pack), and never write it to a file the command step can read.
# T10 STEP_KEY IS EMPTY WHEN THE STEP HAS NO `key:`. The default subject then ends
#     in ":step:" with nothing after it, and as an AWS session tag the null value
#     is presented as "" rather than omitted. A policy keyed on step_key matches
#     every keyless step in the pipeline.
#
# Requires: buildkite-agent v3.121.0+ (token minting), jq (claim inspection).
# `sub` inspection needs no network — it decodes the JWT payload locally.
# Run the mint/inspect functions INSIDE a job; run install/audit on the agent host.
# =============================================================================

set -euo pipefail

AGENT_HOOKS_PATH="${BUILDKITE_AGENT_HOOKS_PATH:-/etc/buildkite-agent/hooks}"
BK_AGENT="${BK_AGENT:-buildkite-agent}"

# Claim names Buildkite accepts as a subject. Verified list, docs
# pages/agent/cli/reference/oidc.md "Custom subject claims".
SUBJECT_CLAIMS_ALLOWED="organization_id pipeline_id cluster_id queue_id build_id job_id agent_id"
# Subjects that are strictly wider than the default compound subject. Allowed only
# with HTH_ALLOW_BROAD_SUBJECT=1 so that widening is a decision, not a default.
SUBJECT_CLAIMS_BROADENING="organization_id cluster_id queue_id"
# Subjects that change every build and therefore cannot be matched by a static
# cloud trust policy.
SUBJECT_CLAIMS_PER_BUILD="build_id job_id"

# T5b. The ONLY names `--claim` may add, from the docs' "### Optional claims"
# table. `agent_tag:NAME` is handled separately because NAME is operator-chosen.
OPTIONAL_CLAIMS_ALLOWED="organization_id pipeline_id build_id cluster_id cluster_name queue_id queue_key"
# Present in every token already. Passing one of these to --claim is the mistake
# T5b describes: it looks like scoping and adds nothing.
DEFAULT_CLAIMS="organization_slug pipeline_slug build_number build_branch build_tag build_commit step_key job_id agent_id build_source runner_environment"

# HTH Guide Excerpt: begin cli-oidc-subject-request
# Mint a token with an explicit, immutable subject. Run inside a Buildkite job:
# --job defaults from $BUILDKITE_JOB_ID and the command requires it.

require_agent() {
  command -v "${BK_AGENT}" >/dev/null 2>&1 || {
    echo "FATAL: '${BK_AGENT}' not on PATH. Requires buildkite-agent v3.121.0+." >&2
    exit 127
  }
  command -v jq >/dev/null 2>&1 || { echo "FATAL: jq required." >&2; exit 127; }
}

# T1: reject a UUID passed where a claim NAME belongs, and refuse to silently
# broaden the trust boundary. This is the guard the guide's one-line prose lacks.
assert_subject_claim() {
  local claim="$1" ok=0 c

  if printf '%s' "${claim}" | grep -qiE '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
    echo "FATAL: '--subject-claim ${claim}' passes a UUID where a claim NAME belongs." >&2
    echo "       Pass the key (e.g. pipeline_id); Buildkite supplies the value." >&2
    exit 3
  fi

  for c in ${SUBJECT_CLAIMS_ALLOWED}; do [ "${c}" = "${claim}" ] && ok=1; done
  if [ "${ok}" -ne 1 ]; then
    echo "FATAL: '${claim}' is not an accepted subject claim." >&2
    echo "       Accepted: ${SUBJECT_CLAIMS_ALLOWED}" >&2
    echo "       Slugs and branch names are refused by Buildkite by design —" >&2
    echo "       renaming them would silently break trust relationships." >&2
    exit 3
  fi

  for c in ${SUBJECT_CLAIMS_PER_BUILD}; do
    [ "${c}" = "${claim}" ] && {
      echo "WARNING: '${claim}' changes on every build. No static cloud trust" >&2
      echo "         policy can match it on 'sub'." >&2
    }
  done

  for c in ${SUBJECT_CLAIMS_BROADENING}; do
    if [ "${c}" = "${claim}" ] && [ "${HTH_ALLOW_BROAD_SUBJECT:-0}" != "1" ]; then
      echo "FATAL: '${claim}' is WIDER than the default compound subject — every" >&2
      echo "       pipeline in that ${claim%%_id} presents an identical 'sub'." >&2
      echo "       It buys immutability by discarding pipeline, ref, commit and" >&2
      echo "       step. If the relying party genuinely requires it, re-run with" >&2
      echo "       HTH_ALLOW_BROAD_SUBJECT=1 and carry the real scoping in claim" >&2
      echo "       conditions (build_branch, step_key, pipeline_id)." >&2
      exit 3
    fi
  done
}

# T5b: refuse a default claim passed where an OPTIONAL claim name belongs. Reading
# `--claim "build_branch"` as a scoping control is the specific mistake this
# catches; the value is already in the token and the flag cannot add it.
assert_optional_claims() {
  local csv="$1" claim ok d list

  # Commas to spaces rather than `local IFS=,`: the allow-lists below are
  # space-separated, and re-scoping IFS would stop THEM splitting.
  list="$(printf '%s' "${csv}" | tr ',' ' ')"

  for claim in ${list}; do
    [ -n "${claim}" ] || continue

    # agent_tag:NAME — the suffix is an operator-chosen agent tag, not a fixed
    # name, so only the prefix can be checked.
    case "${claim}" in agent_tag:?*) continue ;; esac

    for d in ${DEFAULT_CLAIMS}; do
      if [ "${d}" = "${claim}" ]; then
        echo "FATAL: '${claim}' is a DEFAULT claim — every token already carries it." >&2
        echo "       --claim adds from the optional table only: ${OPTIONAL_CLAIMS_ALLOWED}" >&2
        echo "       Condition on '${claim}' in the relying party's policy instead;" >&2
        echo "       for AWS, carry it with --aws-session-tag, which DOES accept" >&2
        echo "       default claims." >&2
        exit 3
      fi
    done

    ok=0
    for d in ${OPTIONAL_CLAIMS_ALLOWED}; do [ "${d}" = "${claim}" ] && ok=1; done
    if [ "${ok}" -ne 1 ]; then
      echo "FATAL: '${claim}' is not an addable claim." >&2
      echo "       Accepted: ${OPTIONAL_CLAIMS_ALLOWED} agent_tag:<NAME>" >&2
      exit 3
    fi
  done
}

# T7 audience, T6 lifetime, T4 no redundant --claim for the subject itself.
# T5: extra claims go in ONE comma-separated --claim, never --claims.
# T5b: and only OPTIONAL claims may go in it. The default adds organization_id —
# the immutable counterpart to the mutable organization_slug the token already
# carries — so a relying party can pin the tenant to a UUID that survives a
# rename. Branch and step are deliberately absent: they are default claims,
# present already, and --claim cannot add them. Pass "" to send no --claim at all.
# If you ever set --subject-claim organization_id (which needs
# HTH_ALLOW_BROAD_SUBJECT=1 and is refused otherwise), drop it from extra-claims:
# T4 — the subject claim is auto-included and repeating it is redundant.
request_token() {
  local audience="${1:?audience required, e.g. sts.amazonaws.com}"
  local subject_claim="${2:?subject claim name required, e.g. pipeline_id}"
  local lifetime="${3:-900}"
  local extra_claims="${4-organization_id}"

  require_agent
  assert_subject_claim "${subject_claim}"
  assert_optional_claims "${extra_claims}"

  [ "${lifetime}" -ge 1 ] 2>/dev/null || {
    echo "FATAL: lifetime must be a positive integer of seconds. 0 means 'API" >&2
    echo "       default' (5 minutes), not 'unlimited'." >&2
    exit 3
  }

  if [ -z "${extra_claims}" ]; then
    "${BK_AGENT}" oidc request-token \
      --audience "${audience}" \
      --subject-claim "${subject_claim}" \
      --lifetime "${lifetime}"
  else
    "${BK_AGENT}" oidc request-token \
      --audience "${audience}" \
      --subject-claim "${subject_claim}" \
      --lifetime "${lifetime}" \
      --claim "${extra_claims}"
  fi
}

# AWS variant. The audience is fixed by STS, and the claims that a trust policy
# will test go in as SESSION TAGS (nested under "https://aws.amazon.com/tags")
# rather than plain claims, because that is the only form
# sts:AssumeRoleWithWebIdentity can condition on. The role's trust policy must
# also permit sts:TagSession.
#
# The default tag set below deliberately mixes DEFAULT claims (organization_slug,
# build_branch, build_source) with an OPTIONAL one (pipeline_id), which would be
# rejected by assert_optional_claims one function up. That is not an
# inconsistency: --aws-session-tag takes "any of the supported claims" (docs, "AWS
# session tags") and the vendor's own example tags organization_slug, whereas
# --claim adds from the optional table only (T5b). Session tags are where branch
# and step conditions belong on AWS.
request_token_aws() {
  local subject_claim="${1:-pipeline_id}"
  local lifetime="${2:-900}"
  local session_tags="${3:-organization_slug,pipeline_id,build_branch,build_source}"

  require_agent
  assert_subject_claim "${subject_claim}"

  "${BK_AGENT}" oidc request-token \
    --audience "sts.amazonaws.com" \
    --subject-claim "${subject_claim}" \
    --lifetime "${lifetime}" \
    --aws-session-tag "${session_tags}"
}
# HTH Guide Excerpt: end cli-oidc-subject-request

# HTH Guide Excerpt: begin cli-oidc-environment-hook
# The agent-side scoping the pipeline cannot override (T3).
#
# Ordering is what makes this work: the agent `environment` hook runs BEFORE any
# non-vendored plugin's `environment` hook (docs/agent/v3/hooks — vendored plugin
# environment hooks are singled out as the exception, running after checkout).
# So this file sets BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM before
# aws-assume-role-with-web-identity or gcp-workload-identity-federation mints
# anything, and mints the Vault JWT before vault-secrets looks for it.
#
# It lives on the agent host under hooks-path. It is not in the build's
# repository, so a pull request cannot change the subject of its own token.
#
# ── ⚠️ THE HOOK FILE IS SHARED. DO NOT WRITE IT WHOLE. ──────────────────────
# An agent has exactly ONE ${hooks-path}/environment, and control 3.9
# (packs/buildkite/config/hth-buildkite-3.09-agent-env.sh) needs the same file:
# it is the only place BUILDKITE_CLEAN_CHECKOUT is read, and the only place that
# can win the GIT_SSH_COMMAND first-wins race. A whole-file `cat >` by either
# pack silently deletes the other control — and neither `audit` verb would see
# it, because each greps for its own settings elsewhere. Adopt 3.6 then 3.9 that
# way round and every OIDC token quietly reverts to the default compound subject
# while three PASSes print.
#
# So both packs write a DELIMITED BLOCK and rewrite only their own:
#   # >>> HTH-BLOCK <id>
#   ...
#   # <<< HTH-BLOCK <id>
# hth_write_hook_block() below is byte-identical in 3.6 and 3.9 apart from the
# block id. It preserves every other line in the file — the other pack's block,
# and any hook the operator wrote themselves — and takes a timestamped backup
# before touching anything. Running either pack twice is idempotent.

# The one line that differs between the two copies of this protocol.
HTH_HOOK_BLOCK_ID="hth-3.6-oidc-subject"

# $1 = hook path, $2 = block id, block body on stdin.
hth_write_hook_block() {
  local hook="$1" id="$2"
  local dir tmp begin end
  dir="$(dirname "${hook}")"
  begin="# >>> HTH-BLOCK ${id}"
  end="# <<< HTH-BLOCK ${id}"

  [ -d "${dir}" ] || { echo "FATAL: hooks-path '${dir}' does not exist." >&2; exit 5; }
  [ -w "${dir}" ] || { echo "FATAL: cannot write '${dir}' (run as root)." >&2; exit 5; }

  tmp="$(mktemp "${dir}/.hth-environment.XXXXXX")"

  if [ -e "${hook}" ]; then
    # Backup first, always — including when the result will be identical. A hook
    # is arbitrary code that runs as the agent user on every job; there is no
    # such thing as an edit here that is not worth being able to undo. The
    # counter matters: the stamp has one-second resolution, and installing 3.6
    # then 3.9 back to back lands in the same second, so a bare stamp would let
    # the second install overwrite the backup of the operator's ORIGINAL file.
    # A backup is never overwritten. (`environment.hth-bak.*` is inert — the
    # agent looks up hooks by exact filename, not by glob.)
    local stamp bak n=0
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    bak="${hook}.hth-bak.${stamp}"
    while [ -e "${bak}" ]; do n=$((n + 1)); bak="${hook}.hth-bak.${stamp}-${n}"; done
    cp -p "${hook}" "${bak}"
    echo "Backed up ${hook} -> ${bak}"

    # Carry over everything except a previous copy of THIS block. awk with
    # index() rather than a regex: the markers contain > and < and the id
    # contains dots, none of which should be read as metacharacters.
    awk -v b="${begin}" -v e="${end}" '
      index($0, b) == 1 { skip = 1; next }
      index($0, e) == 1 { skip = 0; next }
      !skip { print }
    ' "${hook}" >"${tmp}"

    # An `exit` in code that already ran means this block never will. Cheap to
    # detect, invisible at runtime (the hook "succeeds" and does nothing).
    # Only unmanaged lines are scanned: the sibling pack's block legitimately
    # exits to refuse a job, and warning about that every run would be noise.
    if awk '
         /^# >>> HTH-BLOCK / { skip = 1; next }
         /^# <<< HTH-BLOCK / { skip = 0; next }
         !skip { print }
       ' "${tmp}" | grep -qE '^[[:space:]]*exit([[:space:]]|$)'; then
      echo "WARN: ${hook} contains an 'exit' outside any HTH-BLOCK. If it runs" >&2
      echo "      before the block below, the block never executes." >&2
    fi
  else
    cat >"${tmp}" <<'HEADEOF'
#!/usr/bin/env bash
# Buildkite agent `environment` hook.
# Runs once per job, before checkout and before every plugin environment hook.
# Sections delimited by "HTH-BLOCK <id>" markers are managed by How to Harden
# packs and are rewritten in place; edit outside them.
set -euo pipefail
HEADEOF
  fi

  printf '\n%s\n' "${begin}" >>"${tmp}"
  cat >>"${tmp}"
  printf '%s\n' "${end}" >>"${tmp}"

  chmod 0755 "${tmp}"
  chown root:root "${tmp}" 2>/dev/null || true
  mv "${tmp}" "${hook}"
}

install_environment_hook() {
  local hook="${AGENT_HOOKS_PATH}/environment"

  hth_write_hook_block "${hook}" "${HTH_HOOK_BLOCK_ID}" <<'HOOKEOF'
# OIDC subject scoping. Managed by HTH control 3.6.

# Unconditional assignment, never a ${VAR:-default}: a pipeline.yml `env:` block
# is applied to the job environment, and deferring to an inherited value would
# let the repository choose its own token subject.
export BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM="pipeline_id"

# Per-pipeline / per-step widening or narrowing, decided here rather than in the
# repository. BUILDKITE_PIPELINE_SLUG and BUILDKITE_STEP_KEY are protected
# read-only job variables, so a pipeline cannot forge its way into another
# branch of this case. BUILDKITE_STEP_KEY is EMPTY for a step with no `key:`.
case "${BUILDKITE_PIPELINE_SLUG:-}" in
  payments-service)
    case "${BUILDKITE_STEP_KEY:-}" in
      deploy-prod)
        # Cluster-wide subject: accepted here only because this queue is a
        # dedicated production cluster (control 3.2) and the relying party
        # demands an exact-match subject. Strictly WIDER than the default —
        # the branch and step conditions live in the cloud trust policy.
        export BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM="cluster_id"
        ;;
      "")
        echo "hth-3.6: refusing to mint an OIDC token for a step with no 'key:'" >&2
        echo "         in pipeline '${BUILDKITE_PIPELINE_SLUG}'. Add a step key." >&2
        exit 1
        ;;
    esac
    ;;
esac

# Vault's plugin does not mint a token; it reads one from the environment. Mint
# it here so it exists before the vault-secrets environment hook runs. The
# audience must match the `bound_audiences` on the Vault JWT role.
#
# No --claim here. The Vault JWT role's bound_claims are written against
# build_branch / step_key / pipeline_slug, and all three are DEFAULT claims that
# every token already carries — --claim adds from the optional table only and
# cannot re-add them. organization_id is the one worth adding: it pins the role to
# a tenant UUID that survives an organization rename, unlike organization_slug.
if [ "${BUILDKITE_PIPELINE_SLUG:-}" = "payments-service" ] &&
   [ "${BUILDKITE_STEP_KEY:-}" = "db-migrate" ]; then
  BUILDKITE_OIDC_VAULT_JWT="$(buildkite-agent oidc request-token \
    --audience "https://vault.internal.example.com" \
    --subject-claim "${BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM}" \
    --lifetime 300 \
    --claim "organization_id")"
  export BUILDKITE_OIDC_VAULT_JWT
fi
HOOKEOF

  echo "Wrote block '${HTH_HOOK_BLOCK_ID}' in ${hook}."
  echo "Restart buildkite-agent, then run: $0 audit ${AGENT_HOOKS_PATH}"
}
# HTH Guide Excerpt: end cli-oidc-environment-hook

# HTH Guide Excerpt: begin cli-oidc-subject-verify
# Prove what the token actually says, rather than what the pipeline intended.
# Decodes the JWT payload locally — no network, no verification of the signature
# (that is the relying party's job; this is a configuration check).

decode_jwt_payload() {
  local jwt="${1:?jwt required}" payload
  payload="$(printf '%s' "${jwt}" | cut -d. -f2)"
  # base64url -> base64, then pad to a multiple of 4.
  payload="$(printf '%s' "${payload}" | tr '_-' '/+')"
  case $(( ${#payload} % 4 )) in
    2) payload="${payload}==" ;;
    3) payload="${payload}=" ;;
  esac
  # GNU coreutils uses -d; BSD/macOS uses -D.
  printf '%s' "${payload}" | base64 -d 2>/dev/null ||
    printf '%s' "${payload}" | base64 -D
}

# Fails closed when the minted subject is not the one that was asked for — the
# exact symptom of T2 (a plugin minting a default compound subject while the
# cloud policy expects a bare UUID).
verify_subject() {
  local jwt="${1:?jwt required}" expect_claim="${2:?expected subject claim name required}"
  local payload sub expect_value rc=0

  command -v jq >/dev/null 2>&1 || { echo "FATAL: jq required." >&2; exit 127; }
  payload="$(decode_jwt_payload "${jwt}")"

  sub="$(jq -r '.sub // empty' <<<"${payload}")"
  expect_value="$(jq -r --arg c "${expect_claim}" '.[$c] // empty' <<<"${payload}")"

  echo "iss  : $(jq -r '.iss // "<absent>"' <<<"${payload}")"
  echo "aud  : $(jq -r '.aud // "<absent>"' <<<"${payload}")"
  echo "sub  : ${sub:-<absent>}"
  echo "exp-iat (s): $(jq -r 'if .exp and .iat then (.exp - .iat) else "<unknown>" end' <<<"${payload}")"

  local is_default=0
  case "${sub}" in organization:*:pipeline:*) is_default=1 ;; esac

  if [ "${is_default}" -eq 1 ]; then
    echo "SUBJECT: default compound (org/pipeline/ref/commit/step)."
    echo "FAIL: expected the subject to be the '${expect_claim}' value, but the" >&2
    echo "      token carries the DEFAULT compound subject. The token was minted" >&2
    echo "      without --subject-claim and without BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM" >&2
    echo "      in scope — neither cloud plugin passes that flag itself." >&2
    rc=1
  elif [ -z "${expect_value}" ]; then
    echo "FAIL: claim '${expect_claim}' is absent from the token, so the subject" >&2
    echo "      cannot have come from it." >&2
    rc=1
  elif [ "${sub}" != "${expect_value}" ]; then
    echo "FAIL: sub does not equal the '${expect_claim}' value ('${expect_value}')." >&2
    rc=1
  else
    echo "PASS: sub is the ${expect_claim} value."
  fi

  # T9/T6: a long-lived bearer token is the residual risk of the whole control.
  local life
  life="$(jq -r 'if .exp and .iat then (.exp - .iat) else -1 end' <<<"${payload}")"
  if [ "${life}" -gt 3600 ] 2>/dev/null; then
    echo "WARN: token lifetime ${life}s exceeds one hour. It is a bearer credential" >&2
    echo "      for that entire window; nothing binds it to the process that minted it." >&2
  fi

  return "${rc}"
}

# Host-side review. Catches the configurations that turn this control off: a
# repository choosing its own subject, redaction being disabled, and — the one
# this pack used to be blind to — the agent-side block being gone. Nothing here
# greps the hook file until now, so a whole-file overwrite by another pack (or by
# a config-management run) removed the entire control while every check passed.
audit_oidc_usage() {
  local root="${1:-.}" rc=0 hits
  local hook="${AGENT_HOOKS_PATH}/environment"

  echo "scanning: ${root}"

  # 0. Is the control still installed on this host? Only meaningful where the
  # hooks-path exists, i.e. when auditing an agent rather than a repository.
  if [ -d "${AGENT_HOOKS_PATH}" ]; then
    if [ ! -e "${hook}" ]; then
      echo "FAIL: ${hook} does not exist. Nothing sets" >&2
      echo "      BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM off-repo, so every token" >&2
      echo "      carries the default compound subject. Run: $0 install-hook" >&2
      rc=1
    elif ! grep -q "HTH-BLOCK ${HTH_HOOK_BLOCK_ID}" "${hook}"; then
      echo "FAIL: ${hook} exists but carries no '${HTH_HOOK_BLOCK_ID}' block." >&2
      echo "      Either it was never installed, or something rewrote the file" >&2
      echo "      whole — control 3.9 writes the same hook. Check for a" >&2
      echo "      ${hook}.hth-bak.* sibling, then re-run: $0 install-hook" >&2
      rc=1
    elif ! grep -q 'BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM' "${hook}"; then
      echo "FAIL: the '${HTH_HOOK_BLOCK_ID}' block no longer sets" >&2
      echo "      BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM." >&2
      rc=1
    else
      echo "PASS: ${hook} carries the ${HTH_HOOK_BLOCK_ID} block and sets the subject claim."
    fi

    # A hook anyone but root can rewrite is arbitrary code on every job, and
    # would let the pipeline's own owners restore a subject of their choosing.
    if [ -e "${hook}" ] && [ -n "$(find "${hook}" -perm -g+w -o -perm -o+w 2>/dev/null)" ]; then
      echo "FAIL: ${hook} is group- or world-writable. The off-repo guarantee this" >&2
      echo "      control depends on is only as strong as the file's permissions." >&2
      rc=1
    fi
  fi

  hits="$(grep -rIn --include='*.yml' --include='*.yaml' \
          'BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM' "${root}" 2>/dev/null || true)"
  if [ -n "${hits}" ]; then
    echo "FAIL: pipeline YAML sets the OIDC subject claim. Anyone who can merge to" >&2
    echo "      this repository can then widen their own token's subject. Move it" >&2
    echo "      to the agent 'environment' hook." >&2
    printf '%s\n' "${hits}" >&2
    rc=1
  else
    echo "PASS: no pipeline YAML sets BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM."
  fi

  hits="$(grep -rIn -e '--skip-redaction' \
          -e 'BUILDKITE_AGENT_OIDC_REQUEST_TOKEN_SKIP_TOKEN_REDACTION' \
          "${root}" 2>/dev/null || true)"
  if [ -n "${hits}" ]; then
    echo "FAIL: OIDC token redaction is disabled somewhere in this tree. The raw" >&2
    echo "      JWT will be printed to the build log." >&2
    printf '%s\n' "${hits}" >&2
    rc=1
  else
    echo "PASS: OIDC log redaction is not disabled."
  fi

  # --claims is not a flag; the request fails outright. Cheap to catch statically.
  hits="$(grep -rIn -e '--claims' "${root}" 2>/dev/null || true)"
  if [ -n "${hits}" ]; then
    echo "FAIL: '--claims' is not a buildkite-agent flag. The flag is '--claim'," >&2
    echo "      taking one comma-separated value." >&2
    printf '%s\n' "${hits}" >&2
    rc=1
  fi

  # T5b. A default claim passed to --claim reads as scoping and is not. Matched on
  # the same line as the flag so an --aws-session-tag carrying the same name — which
  # is correct — is not flagged.
  hits="$(grep -rIn -E -e '--claim[ =]"?[^"]*\b(organization_slug|pipeline_slug|build_number|build_branch|build_tag|build_commit|step_key|runner_environment|build_source)\b' \
          "${root}" 2>/dev/null || true)"
  if [ -n "${hits}" ]; then
    echo "WARN: '--claim' is passed a DEFAULT claim, which every token already" >&2
    echo "      carries. --claim adds from the optional table only" >&2
    echo "      (${OPTIONAL_CLAIMS_ALLOWED} agent_tag:<NAME>)." >&2
    echo "      Condition on it in the relying party's policy, or on AWS carry it" >&2
    echo "      with --aws-session-tag, which does accept default claims." >&2
    printf '%s\n' "${hits}" >&2
  fi

  return "${rc}"
}
# HTH Guide Excerpt: end cli-oidc-subject-verify

case "${1:-help}" in
  request)      shift; request_token "$@" ;;
  request-aws)  shift; request_token_aws "$@" ;;
  install-hook) install_environment_hook ;;
  verify)       shift; verify_subject "$@" ;;
  audit)        shift; audit_oidc_usage "${1:-.}" ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-3.06-oidc-subject.sh request <audience> <subject-claim> [lifetime] [extra-claims]
  hth-buildkite-3.06-oidc-subject.sh request-aws [subject-claim] [lifetime] [session-tags]
  hth-buildkite-3.06-oidc-subject.sh install-hook          write the agent environment hook
  hth-buildkite-3.06-oidc-subject.sh verify <jwt> <claim>  prove sub == that claim's value
  hth-buildkite-3.06-oidc-subject.sh audit [path]          scan a repo/host tree (exit 1 on fail)
                                                           also checks the agent hook when
                                                           $BUILDKITE_AGENT_HOOKS_PATH exists

subject-claim is a claim NAME, never a UUID. Accepted:
  organization_id pipeline_id cluster_id queue_id build_id job_id agent_id
organization_id / cluster_id / queue_id are BROADER than the default subject and
require HTH_ALLOW_BROAD_SUBJECT=1.

extra-claims goes to --claim, which ADDS optional claims only:
  organization_id pipeline_id build_id cluster_id cluster_name queue_id queue_key
  agent_tag:<NAME>
Default is organization_id; pass "" for none. build_branch, step_key, build_source
and the other default claims are in every token already and are REJECTED here —
put those conditions in the relying party's policy, or (AWS only) in session-tags.

request/request-aws must run inside a job (--job defaults from BUILDKITE_JOB_ID).
install-hook runs on the agent host; restart buildkite-agent afterwards.
USAGE
    exit 2 ;;
esac
