#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.5: Manage Build Secrets — agent-side log redaction
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 3.11 | NIST 800-53 SC-28, SI-11
# Source: https://howtoharden.com/guides/buildkite/#35-manage-build-secrets
#
# PAIRS WITH: packs/buildkite/terraform/hth-buildkite-3.05-cluster-secrets.tf
#             packs/buildkite/api/hth-buildkite-3.05-pipeline-env-scan.sh
# The Terraform pack stores the secret and scopes who may read it; the API pack
# finds secrets sitting in pipeline settings. This one is the last line: it stops
# a value that reached the job from being written into a build log.
#
# WHY THIS PACK EXISTS AT ALL. Guide 3.5 says Buildkite secrets are "automatically
# redacted from build logs", which is true and is also the narrower half of the
# story. That automatic redaction knows about values Buildkite itself issued. It
# knows nothing about a credential your `environment` hook pulled out of Vault,
# AWS Secrets Manager or GCP Secret Manager — which is precisely the delivery
# path Step 1 of this control tells you to prefer. `redacted-vars` is the
# mechanism that covers those, and the guide never names it.
#
# AGENT MAJOR VERSION: targets buildkite-agent **v3** (current major). Config
# keys, environment variable names and the default pattern list were read from
# buildkite.com/docs/agent/v3/configuration; the length floor was read from
# github.com/buildkite/agent internal/redact/redact.go.
#
# ── ⚠️ TRAP 1: setting redacted-vars REPLACES the defaults ──────────────────
# This is the whole reason the pack is an appender and not a writer. The agent
# applies its built-in list only while the setting is ABSENT. The moment you set
# `redacted-vars` — in the cfg, via $BUILDKITE_REDACTED_VARS, or with
# --redacted-vars — your list is the entire list. Adding one pattern by writing
# `redacted-vars="*_PASSWORD,MY_THING"` does not add one pattern; it deletes
# seven and keeps two. Nothing warns you: builds keep passing and the logs quietly
# stop being redacted.
#
# ── ⚠️ TRAP 2: the vendor's own two pages disagree on the default ───────────
# The agent v3 configuration reference documents NINE patterns:
#   *_PASSWORD  *_SECRET  *_TOKEN  *_PRIVATE_KEY  *_SSH_KEY
#   *_ACCESS_KEY  *_SECRET_KEY  *_CONNECTION_STRING  *_API_KEY
# Shorter lists circulate in other Buildkite documentation and in most blog
# posts, and the two patterns that go missing from them are *_SSH_KEY and
# *_API_KEY — deploy keys and API keys, i.e. the two most likely things in a CI
# environment. An operator copying a seven-item list from memory silently drops
# both. HTH_REDACTED_DEFAULTS below is the nine-item reference list, and `apply`
# always unions it in, so the appender cannot regress the baseline even if the
# machine's current setting is already a truncated copy.
#
# ── ⚠️ TRAP 3: matching is on the NAME, and it is suffix-anchored ───────────
# `*_TOKEN` matches VAULT_TOKEN and does not match TOKEN_VAULT, MYTOKEN or
# `tokenValue`. So redaction coverage is a naming-convention problem: a Vault
# lease exported as DBPASS is not redacted by any default pattern, and neither is
# anything a third-party plugin exports under a name you do not control. Fix it
# by naming variables to match, by adding patterns here, or — for values whose
# name you cannot influence — by registering the VALUE directly (see the
# redact-external-secrets region, which does not care about names at all).
#
# ── ⚠️ TRAP 4: values under 6 bytes are never redacted ──────────────────────
# From internal/redact/redact.go, verbatim:
#     const LengthMin = 6
#     "LengthMin is the shortest string length that will be considered a
#      potential secret by the environment redactor. e.g. if the redactor is
#      configured to filter out environment variables matching *_TOKEN, and
#      API_TOKEN is set to "none", this minimum length will prevent the word
#      "none" from being redacted from useful log output."
# The rationale is sound and the consequence is still a hole: a 4-character PIN,
# a short shared secret or a truncated token in a *_TOKEN variable is printed in
# clear no matter how this pack is configured. Short secrets must be lengthened
# or moved off this path; `audit` reports the floor so it is never a surprise.
# (The same floor is what `redactor add --apply-vars-filter` applies.)
#
# ── ⚠️ TRAP 5: the environment snapshot happens before your hook's later work ─
# The environment redactor works from variables present in the job environment.
# A secret fetched mid-command into a shell variable — `TOKEN=$(vault read ...)`
# inside a step script — was never in that environment and is not covered by any
# pattern. `buildkite-agent redactor add` is the supported path for those, and it
# is the second region of this pack.
#
# ── ⚠️ TRAP 6: redaction is a log filter, not a control boundary ────────────
# It rewrites log output. It does not redact uploaded artifacts, does not touch
# the pipeline payloads that the 3.5 API pack scans, and cannot recognise a value
# the job transformed before printing (base64, a URL-encoded query string, a
# secret split across two echo calls). Treat a redacted log as damage limitation
# after something already went wrong, never as the reason it was safe to put the
# secret there.
#
# ── ⚠️ TRAP 7: the agent reads its config once, at start ────────────────────
# Every function here writes files and restarts nothing. Apply, restart the
# agent, then re-audit — an audit run against a config the running agent has not
# loaded reports the intent, not the behaviour.
#
# ── VERIFICATION STATUS: DRIFT-CHECKED-ONLY ────────────────────────────────
# `buildkite-agent` is not installed in the authoring environment, so no command
# below was executed against a real agent. The config key, the environment
# variable name, the CLI flag and the nine default patterns were read from the
# agent v3 configuration reference; `redactor add`, its `--format json`,
# `--apply-vars-filter` and `--redacted-vars` flags and its stdin/file input
# forms were read from the agent v3 redactor CLI reference; the 6-byte floor was
# read from the agent source. The pure-shell merge logic (parse -> union ->
# dedupe -> write) WAS exercised locally against fixture config files, including
# the truncated-default case TRAP 2 describes.
#
# Requires: a writable buildkite-agent config. Run on the AGENT host.
# =============================================================================

set -euo pipefail

AGENT_CFG="${BUILDKITE_AGENT_CONFIG:-/etc/buildkite-agent/buildkite-agent.cfg}"

# TRAP 2: the nine-pattern reference list from the agent v3 configuration docs.
# This is a floor, never a replacement — `apply` unions it with whatever the host
# already has plus whatever the operator adds.
HTH_REDACTED_DEFAULTS='*_PASSWORD,*_SECRET,*_TOKEN,*_PRIVATE_KEY,*_SSH_KEY,*_ACCESS_KEY,*_SECRET_KEY,*_CONNECTION_STRING,*_API_KEY'

# Site-specific additions. TRAP 3: add the names your secret delivery actually
# uses when you cannot rename the variables to match a default glob.
HTH_REDACTED_EXTRA="${HTH_REDACTED_EXTRA:-}"

# HTH Guide Excerpt: begin append-redacted-vars
# Read the value the agent would actually use. An ABSENT setting means the agent
# applies its built-in defaults; an empty or present setting means the file wins
# (TRAP 1). Those two states are reported differently on purpose.
read_cfg_redacted_vars() {
  [ -r "${AGENT_CFG}" ] || return 1
  sed -nE 's|^[[:space:]]*redacted-vars[[:space:]]*=[[:space:]]*(.*)$|\1|p' "${AGENT_CFG}" \
    | tail -1 \
    | sed -E 's/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/'
}

# Split on commas, trim, drop blanks, de-duplicate while preserving first-seen
# order so a diff of the config file stays readable across runs.
normalise_patterns() {
  tr ',' '\n' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | grep -v '^$' \
    | awk '!seen[$0]++'
}

# The union that makes this an appender: whatever is configured now, plus the
# documented defaults, plus the operator's additions. Running it twice changes
# nothing; running it on a truncated list repairs the list.
merged_patterns() {
  local current=""
  current="$(read_cfg_redacted_vars || true)"
  printf '%s\n%s\n%s\n' "${current}" "${HTH_REDACTED_DEFAULTS}" "${HTH_REDACTED_EXTRA}" \
    | normalise_patterns
}

show() {
  local current
  current="$(read_cfg_redacted_vars || true)"
  echo "config file      : ${AGENT_CFG}"
  if [ -z "${current}" ]; then
    echo "redacted-vars    : <unset> - the agent applies its built-in defaults"
  else
    echo "redacted-vars    : ${current}"
  fi
  echo
  echo "effective patterns after 'apply' would be:"
  merged_patterns | sed 's/^/  /'
}

# Idempotent single-key upsert, matching the style used by the 3.4 config pack.
set_cfg() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "${AGENT_CFG}"; then
    # Replace via awk rather than sed: the value contains '*' and ',' and must
    # not be reinterpreted as part of a replacement expression.
    awk -v k="${key}" -v v="${value}" '
      $0 ~ "^[[:space:]]*" k "[[:space:]]*=" { print k "=\"" v "\""; next }
      { print }' "${AGENT_CFG}" >"${tmp}"
  else
    cat "${AGENT_CFG}" >"${tmp}"
    printf '%s="%s"\n' "${key}" "${value}" >>"${tmp}"
  fi
  cat "${tmp}" >"${AGENT_CFG}"
  rm -f "${tmp}"
}

apply() {
  [ -w "${AGENT_CFG}" ] || { echo "FATAL: cannot write ${AGENT_CFG} (run as root)." >&2; exit 5; }
  local merged
  merged="$(merged_patterns | paste -sd, -)"
  set_cfg "redacted-vars" "${merged}"
  echo "redacted-vars=\"${merged}\""
  echo
  echo "Restart buildkite-agent for this to take effect (TRAP 7), then: $0 audit"
}

# Container / systemd equivalent. TRAP 1 applies identically here: this variable
# REPLACES the built-in list, so it must always carry the full merged set.
print_env_equivalent() {
  printf '# buildkite-agent v3 - redaction via environment (containers, systemd units)\n'
  printf 'BUILDKITE_REDACTED_VARS="%s"\n' "$(merged_patterns | paste -sd, -)"
  printf '# Equivalent CLI flag: buildkite-agent start --redacted-vars "..."\n'
  printf '# This value REPLACES the built-in defaults - never set a partial list.\n'
}
# HTH Guide Excerpt: end append-redacted-vars

# HTH Guide Excerpt: begin audit-redaction
# Fails closed on the regression TRAP 1 and TRAP 2 describe together: a
# redacted-vars that is SET and is missing patterns the agent would have applied
# had it been left alone. That configuration is strictly worse than no
# configuration, and it looks deliberate.
audit_redaction() {
  local current rc=0 missing=""
  current="$(read_cfg_redacted_vars || true)"

  echo "config file   : ${AGENT_CFG}"
  echo "redacted-vars : ${current:-<unset>}"
  echo "length floor  : 6 bytes (internal/redact/redact.go LengthMin) - shorter values are never redacted"
  echo

  if [ -z "${current}" ]; then
    echo "PASS: unset, so the agent applies all nine built-in patterns."
    echo "NOTE: that baseline covers no name outside the default globs. If secrets"
    echo "      arrive from Vault or a cloud secret manager under other names, run"
    echo "      '$0 apply' with HTH_REDACTED_EXTRA set (TRAP 3)."
  else
    local p
    while IFS= read -r p; do
      [ -n "${p}" ] || continue
      printf '%s\n' "${current}" | normalise_patterns | grep -qxF "${p}" || missing="${missing} ${p}"
    done < <(printf '%s' "${HTH_REDACTED_DEFAULTS}" | normalise_patterns)

    if [ -n "${missing}" ]; then
      echo "FAIL: redacted-vars is set and is MISSING documented default pattern(s):${missing}" >&2
      echo "      Setting this key replaces the built-in list rather than extending it," >&2
      echo "      so these names are no longer redacted from build logs on this agent." >&2
      echo "      Repair with: $0 apply" >&2
      rc=1
    else
      echo "PASS: every documented default pattern is present."
    fi
  fi

  # Not a failure, but the question an auditor asks next.
  if ! grep -qE '^[[:space:]]*redacted-vars[[:space:]]*=' "${AGENT_CFG}" 2>/dev/null; then
    echo
    echo "REMINDER: redaction is a log filter, not a boundary (TRAP 6). It does not"
    echo "          cover artifacts, pipeline settings, or values the job transformed"
    echo "          before printing."
  fi

  return "${rc}"
}
# HTH Guide Excerpt: end audit-redaction

# HTH Guide Excerpt: begin redact-external-secrets
# TRAP 3 and TRAP 5, solved properly. `redacted-vars` matches variable NAMES that
# exist in the job environment. A secret fetched inside a step - the Vault, AWS
# Secrets Manager and GCP Secret Manager path control 3.5 Step 1 prefers - has
# neither property: it may be named anything, and it appeared after the
# environment was taken. `buildkite-agent redactor add` registers the VALUE
# itself, so every later line of the log is filtered regardless of the name.
#
# Emit these as agent hooks (hooks/environment, or a step's pre-command). They
# are printed rather than installed because the fetch command is site-specific.
print_vault_hook() {
  cat <<'HOOKEOF'
#!/usr/bin/env bash
# buildkite-agent v3 - hooks/environment
# Register externally-fetched secrets with the redactor BEFORE anything can echo
# them. Values are piped on stdin so they never appear in argv, in `ps`, or in
# the shell history of a debugging session.
set -euo pipefail

# --- HashiCorp Vault ---------------------------------------------------------
# --format json makes the redactor register every VALUE in the object and ignore
# the keys, which is what you want for a whole secret bundle.
vault kv get -format=json secret/data/ci/deploy \
  | jq -c '.data.data' \
  | buildkite-agent redactor add --format json

# Export afterwards. Registration first means an accidental `set -x` between the
# two lines still prints a redacted value.
DEPLOY_TOKEN="$(vault kv get -field=token secret/data/ci/deploy)"
export DEPLOY_TOKEN

# --- AWS Secrets Manager -----------------------------------------------------
aws secretsmanager get-secret-value --secret-id ci/deploy --query SecretString --output text \
  | buildkite-agent redactor add --format json

# --- GCP Secret Manager ------------------------------------------------------
# A single opaque value: no --format, so the whole input is registered verbatim.
gcloud secrets versions access latest --secret=ci-deploy \
  | buildkite-agent redactor add

# --- A file of key material --------------------------------------------------
# Registers the file's contents; the redactor also accepts a path argument.
buildkite-agent redactor add /tmp/id_ed25519
HOOKEOF
}

# The name-filtered variant. --apply-vars-filter makes `redactor add` honour the
# same rules as the environment redactor: only entries whose NAME matches the
# redacted-vars patterns, and only values of at least 6 bytes (TRAP 4). Use it
# when piping a bundle that legitimately mixes secrets with non-secrets, and
# accept that anything misnamed is skipped.
print_filtered_hook() {
  cat <<'HOOKEOF'
#!/usr/bin/env bash
# buildkite-agent v3 - hooks/environment (name-filtered variant)
set -euo pipefail

# Only object entries whose key matches a redacted-vars pattern are registered,
# and only if the value is at least 6 bytes. Everything else is passed over in
# silence - which is the trade: fewer false redactions, and a misnamed secret is
# NOT protected. Prefer the unfiltered form for a bundle you know is all secret.
vault kv get -format=json secret/data/ci/app \
  | jq -c '.data.data' \
  | buildkite-agent redactor add --format json --apply-vars-filter
HOOKEOF
}
# HTH Guide Excerpt: end redact-external-secrets

case "${1:-audit}" in
  show)          show ;;
  apply)         apply ;;
  audit)         audit_redaction ;;
  env)           print_env_equivalent ;;
  hook)          print_vault_hook ;;
  hook-filtered) print_filtered_hook ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-3.05-redaction.sh show           current vs effective pattern list
  hth-buildkite-3.05-redaction.sh apply          union current + documented defaults + extras
  hth-buildkite-3.05-redaction.sh audit          fail if a default pattern was dropped (exit 1)
  hth-buildkite-3.05-redaction.sh env            container/systemd environment equivalent
  hth-buildkite-3.05-redaction.sh hook           hooks/environment: register fetched secrets
  hth-buildkite-3.05-redaction.sh hook-filtered  same, name-filtered variant

env:
  BUILDKITE_AGENT_CONFIG   path to buildkite-agent.cfg
  HTH_REDACTED_EXTRA       comma-separated extra patterns to append

Setting redacted-vars REPLACES the agent's built-in list. This tool only ever
unions; it never writes a list smaller than the documented defaults.
Restart buildkite-agent after 'apply' - the config is read once at start.
USAGE
    exit 2 ;;
esac
