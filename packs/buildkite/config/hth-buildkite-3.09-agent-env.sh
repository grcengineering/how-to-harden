#!/usr/bin/env bash
# =============================================================================
# HTH Buildkite Control 3.9: Harden the Agent Execution Environment
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.1 | NIST 800-53 CM-6, CM-7
# Source: https://howtoharden.com/guides/buildkite/#39-harden-the-agent-execution-environment
#
# SCOPE BOUNDARY — DOES NOT DUPLICATE 2.4.
# packs/buildkite/config/hth-buildkite-2.04-agent-untrusted-input.sh owns the
# INPUT controls: no-command-eval, allowed-plugins, no-local-hooks,
# allowed-repositories, redacted-vars, enable-environment-variable-allowlist /
# allowed-environment-variables, reject-secrets, pre-bootstrap admission.
# This pack owns the EXECUTION ENVIRONMENT: git host-key trust, workspace
# hygiene between jobs, the bootstrap path, and agent lifetime. Nothing below
# writes a key that pack writes. Run both; they are complementary and neither
# is sufficient alone.
#
# AGENT MAJOR VERSION: buildkite-agent **v3** (no released v4).
#
# AUTHORING STATUS: DRIFT-CHECKED-ONLY for the Buildkite half — buildkite-agent
# is not installed in the authoring environment, so no function below was run
# against a live agent. Every key, env var, default and code path was read from
# github.com/buildkite/agent at main on 2026-08-18:
#   clicommand/agent_start.go:576-579   no-ssh-keyscan / BUILDKITE_NO_SSH_KEYSCAN
#   clicommand/agent_start.go:1011      SSHKeyscan: !cfg.NoSSHKeyscan
#   clicommand/agent_start.go:399-403   disconnect-after-job / BUILDKITE_AGENT_DISCONNECT_AFTER_JOB
#   clicommand/agent_start.go:552-556   bootstrap-script / BUILDKITE_BOOTSTRAP_SCRIPT_PATH
#   clicommand/agent_start.go:855-861   bootstrap default = "<agent-exe> bootstrap"
#   clicommand/global.go:172-177        hooks-path (flag default is EMPTY)
#   internal/job/config.go:85           CleanCheckout `env:"BUILDKITE_CLEAN_CHECKOUT"`
#   internal/job/checkout.go:47         if e.CleanCheckout { removeCheckoutDir() }
#   internal/job/ssh_host_key_checking.go   the whole host-key mechanism
#   internal/job/executor.go:979,1008   keyscan config THEN environment hook
#   internal/job/executor.go:706-733    applyEnvironmentChanges -> ReadFromEnvironment
#   env/protected.go                    which vars a job may not overwrite
#   agent/job_runner.go:306-329         how bootstrap-script is executed
# The OpenSSH precedence finding in T2 is VERIFIED-LIVE — reproduced on this
# machine against OpenSSH_10.3p1 (see T2 for the exact commands and output).
#
# -----------------------------------------------------------------------------
# T1  WHAT `no-ssh-keyscan` ACTUALLY DOES IS NOT WHAT ITS NAME SAYS
# -----------------------------------------------------------------------------
# The agent no longer shells out to ssh-keyscan. ssh_host_key_checking.go
# configures GIT_SSH_COMMAND instead, and the three outcomes are:
#
#   no-ssh-keyscan=false (THE DEFAULT), OpenSSH >= 7.6
#       -o StrictHostKeyChecking=accept-new
#       Trust-on-first-use. The first checkout accepts whatever key answers;
#       changes are rejected afterwards. The MITM window is one connection wide
#       and it is the connection that fetches all of your source code.
#
#   no-ssh-keyscan=false, OpenSSH < 7.6
#       -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
#       This is strictly worse than TOFU and it is not documented as a
#       possibility anywhere the operator will look: host key checking is
#       disabled on EVERY job forever, because the known_hosts file it would
#       compare against is /dev/null. Old distro images land here silently.
#
#   no-ssh-keyscan=true
#       -o StrictHostKeyChecking=yes
#       Checkout FAILS unless the host key is already in known_hosts. Setting
#       this key without provisioning known_hosts does not harden anything; it
#       breaks the agent. apply_host_key_pinning() below refuses to do one
#       without the other.
#
# -----------------------------------------------------------------------------
# T2  ssh -o IS FIRST-WINS AND THE AGENT *APPENDS*, SO A JOB CAN NEUTER T1
# -----------------------------------------------------------------------------
# The good news first: `no-ssh-keyscan` itself cannot be flipped by a pipeline.
# internal/job/config.go:192 declares `SSHKeyscan bool` with NO `env:` tag, and
# BUILDKITE_SSH_KEYSCAN is in env/protected.go. A pipeline.yml cannot set it.
#
# The bad news: it does not have to. ssh_host_key_checking.go builds the command
# by APPENDING to whatever GIT_SSH_COMMAND already holds:
#
#     existingSSHCommand, _ := e.shell.Env.Get("GIT_SSH_COMMAND")
#     if existingSSHCommand == "" { existingSSHCommand = "ssh" }
#     e.shell.Env.Set("GIT_SSH_COMMAND", existingSSHCommand+" "+sshOptions)
#
# and OpenSSH resolves duplicate -o options FIRST-WINS. ssh_config(5): "Unless
# noted otherwise, for each parameter, the first obtained value will be used."
# Reproduced here on OpenSSH_10.3p1:
#
#     $ ssh -o StrictHostKeyChecking=no -o StrictHostKeyChecking=yes -G host
#     stricthostkeychecking false
#     $ ssh -o StrictHostKeyChecking=yes -o StrictHostKeyChecking=no -G host
#     stricthostkeychecking true
#
# So a step carrying
#     env:
#       GIT_SSH_COMMAND: "ssh -o StrictHostKeyChecking=no"
# wins over the agent's appended `=yes`, and neither GIT_SSH_COMMAND nor GIT_SSH
# appears anywhere in env/protected.go, so nothing blocks it. The GIT_SSH escape
# is even cleaner: ssh_host_key_checking.go returns immediately when GIT_SSH is
# set ("GIT_SSH is set, skipping SSH host key configuration"), so the agent
# configures nothing at all.
#
# THE FIX IS THE environment HOOK, AND THE ORDERING IS WHY IT WORKS.
# executor.go calls configureSSHKeyChecking at line 979 and the global
# environment hook at line 1008 — the hook runs LAST, before CheckoutPhase, and
# its exports are applied through applyEnvironmentChanges. A hook that REBUILDS
# GIT_SSH_COMMAND from scratch (rather than appending) and unsets GIT_SSH is
# therefore the final word, whatever the pipeline supplied. git honours
# GIT_SSH_COMMAND over GIT_SSH (git connect.c: GIT_SSH_COMMAND is read first at
# :1172, GIT_SSH only as the fallback at :1406), so rewriting the former closes
# both holes. write_environment_hook() does exactly this.
#
# -----------------------------------------------------------------------------
# T3  `BUILDKITE_CLEAN_CHECKOUT` IN buildkite-agent.cfg IS SILENTLY IGNORED
# -----------------------------------------------------------------------------
# This is the single most expensive misconfiguration in this control, because it
# fails green. BUILDKITE_CLEAN_CHECKOUT is NOT an agent flag: it appears nowhere
# in clicommand/agent_start.go (grep it). It is a job/bootstrap variable —
# internal/job/config.go:85, `CleanCheckout bool \`env:"BUILDKITE_CLEAN_CHECKOUT"\`` —
# consumed at internal/job/checkout.go:47 to call removeCheckoutDir().
#
# buildkite-agent.cfg keys map to CLI flags. An unrecognised key is not a flag,
# so writing `BUILDKITE_CLEAN_CHECKOUT=true` (or `clean-checkout=true`) into the
# config file configures nothing, warns nobody, and leaves the operator
# believing workspaces are wiped between jobs while a poisoned build's leftovers
# sit there for the next one. audit_agent_env() FAILS on finding it there.
#
# The supported paths are exactly two:
#   (a) export it from the agent-level `environment` hook — applied via
#       applyEnvironmentChanges -> ReadFromEnvironment, which refreshes
#       e.CleanCheckout before CheckoutPhase reads it; or
#   (b) run ephemeral agents (disconnect-after-job=true), where there is no
#       second job to contaminate.
# Do (a) on persistent agents. Do (b) where you can. Doing neither is the
# default and it is the finding.
#
# -----------------------------------------------------------------------------
# T4  KEEP THE BOOTSTRAP WRAPPER THIN, AND NEVER LOG ITS ENVIRONMENT
# -----------------------------------------------------------------------------
# agent/job_runner.go:309 shellwords-splits `bootstrap-script` into Path=cmd[0]
# and Args=cmd[1:]. The agent appends NOTHING: the wrapper receives no job data
# in argv, because every piece of it — including BUILDKITE_AGENT_ACCESS_TOKEN —
# arrives in the environment. A wrapper that runs `env`, `set -x`, or `printenv`
# for debugging prints an agent credential into the build log. Keep it to
# `exec buildkite-agent bootstrap "$@"` plus whatever admission check you can
# justify; Buildkite documents no handler contract beyond invoking bootstrap, so
# anything richer is building on unspecified behavior. The wrapper also runs as
# the agent user, so a wrapper the agent user can write to is arbitrary code
# execution as that user on every job — audit_agent_env() checks its ownership
# and mode.
#
# Requires: root (or write access to the agent config, hooks dir and known_hosts).
# Run on the AGENT host. Restart buildkite-agent after any apply-*, then re-audit.
# =============================================================================

set -euo pipefail

AGENT_CFG="${BUILDKITE_AGENT_CONFIG:-/etc/buildkite-agent/buildkite-agent.cfg}"
KNOWN_HOSTS="${BUILDKITE_KNOWN_HOSTS:-/etc/buildkite-agent/known_hosts}"
BOOTSTRAP_WRAPPER="${BUILDKITE_BOOTSTRAP_WRAPPER:-/etc/buildkite-agent/bootstrap-wrapper.sh}"
AGENT_BIN="${BUILDKITE_AGENT_BIN:-/usr/bin/buildkite-agent}"

# Read a single key out of buildkite-agent.cfg (last occurrence wins, matching
# the agent's own file parser). Empty output means "not set".
read_cfg() {
  sed -nE "s|^[[:space:]]*$1[[:space:]]*=[[:space:]]*(.*)$|\1|p" "${AGENT_CFG}" | tail -1
}

# ATOMIC CONFIG REPLACEMENT. buildkite-agent.cfg carries this host's registration
# token; a truncate-then-write (`cat "${tmp}" >"${AGENT_CFG}"`) interrupted by a
# signal, a full disk, or a set -e abort leaves a config the agent cannot parse,
# the agent then fails to start, and the host silently leaves the fleet. Every
# mutation below stages a sibling file and rename(2)s it into place instead, so a
# reader sees the old config or the new one, never a partial one.
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

# Idempotent upsert of `key=value`.
set_cfg() {
  local key="$1" value="$2" tmp dst
  hth_cfg_stage; dst="${HTH_CFG_DST}"; tmp="${HTH_CFG_TMP}"
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "${dst}"; then
    sed -E "s|^[[:space:]]*${key}[[:space:]]*=.*$|${key}=${value}|" "${dst}" >"${tmp}"
  else
    cat "${dst}" >"${tmp}"
    printf '%s=%s\n' "${key}" "${value}" >>"${tmp}"
  fi
  hth_cfg_commit
}

# hooks-path has an EMPTY flag default (global.go:172-177) — the real value comes
# from the packaged config file, and it differs per platform. Derive it, never
# assume it.
hooks_dir() {
  local h
  h="$(read_cfg hooks-path)"
  if [ -z "${h}" ]; then
    h="$(dirname "${AGENT_CFG}")/hooks"
  fi
  printf '%s' "${h}"
}

# HTH Guide Excerpt: begin config-agent-env-hostkeys
# Pin the git host key. Provision known_hosts FIRST, then turn off TOFU —
# reversing that order just breaks every checkout on this agent.

# Capture the server's key, then require a human to confirm the fingerprint out
# of band. This deliberately does not auto-accept: fetching a key over the same
# path an attacker would sit on and calling it verified is TOFU with extra steps.
propose_known_hosts() {
  local host="${1:?usage: propose_known_hosts <git-host> [port]}"
  local port="${2:-22}"
  local staged
  staged="$(mktemp)"

  # ssh-keyscan emits a "# host:port SSH-2.0-..." banner alongside the keys; drop
  # it so an emptiness check cannot pass on a banner alone.
  ssh-keyscan -p "${port}" -t rsa,ecdsa,ed25519 "${host}" 2>/dev/null \
    | grep -vE '^[[:space:]]*(#.*)?$' > "${staged}" || true
  [ -s "${staged}" ] || { echo "FATAL: no host keys returned for ${host}:${port}" >&2; rm -f "${staged}"; exit 3; }

  echo "Fingerprints for ${host}:${port} — CONFIRM THESE against the vendor's"
  echo "published SSH key fingerprints before running accept_known_hosts:"
  ssh-keygen -lf "${staged}"
  echo
  echo "staged file: ${staged}"
  echo "then: $0 accept-known-hosts ${staged}"
}

accept_known_hosts() {
  local staged="${1:?usage: accept_known_hosts <staged-file-from-propose>}"
  [ -s "${staged}" ] || { echo "FATAL: '${staged}' is empty or missing." >&2; exit 3; }

  # Append-and-dedupe so multiple git hosts can be pinned over several runs.
  touch "${KNOWN_HOSTS}"
  sort -u "${KNOWN_HOSTS}" "${staged}" | grep -vE '^[[:space:]]*(#.*)?$' > "${KNOWN_HOSTS}.new"
  mv "${KNOWN_HOSTS}.new" "${KNOWN_HOSTS}"
  chmod 0644 "${KNOWN_HOSTS}"
  echo "known_hosts now pins $(grep -c . "${KNOWN_HOSTS}") key(s) at ${KNOWN_HOSTS}"
}

# Turn off automatic host-key acceptance. Fails closed if known_hosts is not
# populated, because StrictHostKeyChecking=yes with an empty known_hosts is an
# outage, not a control.
apply_host_key_pinning() {
  [ -w "${AGENT_CFG}" ] || { echo "FATAL: cannot write ${AGENT_CFG} (run as root)." >&2; exit 5; }
  if [ ! -s "${KNOWN_HOSTS}" ]; then
    echo "FATAL: ${KNOWN_HOSTS} is empty or missing." >&2
    echo "       Run '$0 propose-known-hosts <git-host>' and verify the fingerprints" >&2
    echo "       first. Setting no-ssh-keyscan=true without this breaks checkout on" >&2
    echo "       every job." >&2
    exit 3
  fi
  set_cfg "no-ssh-keyscan" "true"
  echo "Applied no-ssh-keyscan=true. Restart the agent, then run: $0 audit"
}
# HTH Guide Excerpt: end config-agent-env-hostkeys

# HTH Guide Excerpt: begin config-agent-env-hooks
# The agent-level `environment` hook. This is the ONLY supported place to set
# BUILDKITE_CLEAN_CHECKOUT, and the only place that can win the GIT_SSH_COMMAND
# race, because it runs after the agent configured SSH and before checkout.
#
# ── ⚠️ THE HOOK FILE IS SHARED. DO NOT WRITE IT WHOLE. ──────────────────────
# An agent has exactly ONE ${hooks-path}/environment, and control 3.6
# (packs/buildkite/cli/hth-buildkite-3.06-oidc-subject.sh) needs the same file:
# it is the only off-repo place to set BUILDKITE_OIDC_TOKEN_SUBJECT_CLAIM, and a
# pipeline that can set that variable can widen its own cloud trust. This pack
# previously did `cat > "${hook}"` with no existence check and no backup, so
# adopting 3.6 and then 3.9 deleted 3.6's control outright — silently, because
# neither audit read the other's settings.
#
# So both packs write a DELIMITED BLOCK and rewrite only their own:
#   # >>> HTH-BLOCK <id>
#   ...
#   # <<< HTH-BLOCK <id>
# hth_write_hook_block() below is byte-identical to the copy in pack 3.6 apart
# from the block id. It preserves every other line in the file — the other pack's
# block, and any hook the operator wrote themselves — and takes a timestamped
# backup before touching anything. Running either pack twice is idempotent.

# The one line that differs between the two copies of this protocol.
HTH_HOOK_BLOCK_ID="hth-3.9-agent-env"

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

write_environment_hook() {
  local hooks hook
  hooks="$(hooks_dir)"
  hook="${hooks}/environment"
  mkdir -p "${hooks}"

  # Quoted heredoc so nothing is expanded at write time, piped through sed for
  # the one placeholder. The block body carries no shebang and no `set` — those
  # belong to the file, which hth_write_hook_block owns.
  sed "s|__KNOWN_HOSTS__|${KNOWN_HOSTS}|g" <<'HOOKEOF' | hth_write_hook_block "${hook}" "${HTH_HOOK_BLOCK_ID}"
# git host-key trust + workspace hygiene. Managed by HTH control 3.9.

# --- git host-key trust -----------------------------------------------------
# REBUILT, not appended. ssh resolves duplicate -o options first-wins, so a
# pipeline-supplied GIT_SSH_COMMAND containing StrictHostKeyChecking=no would
# beat the option the agent appends. Discard whatever arrived and state the
# policy from scratch. GIT_SSH is unset because ssh_host_key_checking.go skips
# all configuration when it is present, and git prefers GIT_SSH_COMMAND anyway.
unset GIT_SSH
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=yes -o UserKnownHostsFile=__KNOWN_HOSTS__"

# --- workspace hygiene ------------------------------------------------------
# NOT a buildkite-agent.cfg key. Exported here so applyEnvironmentChanges ->
# ReadFromEnvironment refreshes the executor's CleanCheckout before the checkout
# phase reads it. Drop this block on agents that already run one job and exit
# (disconnect-after-job): re-cloning a workspace nothing else will ever touch is
# pure build time.
export BUILDKITE_CLEAN_CHECKOUT=true

# Do not print the environment from this hook. BUILDKITE_AGENT_ACCESS_TOKEN is
# in it.
HOOKEOF

  echo "Wrote block '${HTH_HOOK_BLOCK_ID}' in ${hook}."
}

# The maximum-control option, kept deliberately thin.
write_bootstrap_wrapper() {
  [ -x "${AGENT_BIN}" ] || { echo "FATAL: agent binary '${AGENT_BIN}' not found or not executable." >&2; exit 3; }

  cat > "${BOOTSTRAP_WRAPPER}" <<HOOKEOF
#!/usr/bin/env bash
set -euo pipefail

# Buildkite documents no handler contract beyond invoking bootstrap, and passes
# no job data in argv — it is all in the environment. Add admission checks here
# ONLY if they read documented BUILDKITE_* variables; never dump the
# environment, which carries BUILDKITE_AGENT_ACCESS_TOKEN.

exec "${AGENT_BIN}" bootstrap "\$@"
HOOKEOF

  chown root:root "${BOOTSTRAP_WRAPPER}" 2>/dev/null || true
  chmod 0755 "${BOOTSTRAP_WRAPPER}"
  set_cfg "bootstrap-script" "${BOOTSTRAP_WRAPPER}"
  echo "Wrote ${BOOTSTRAP_WRAPPER} and pointed bootstrap-script at it."
}

# Ephemeral agents: one job per agent process, then disconnect. Structurally
# removes build-to-build contamination instead of cleaning up after it.
apply_ephemeral() {
  [ -w "${AGENT_CFG}" ] || { echo "FATAL: cannot write ${AGENT_CFG} (run as root)." >&2; exit 5; }
  set_cfg "disconnect-after-job" "true"
  echo "Applied disconnect-after-job=true. Your supervisor must restart the agent"
  echo "after each job, or capacity drops to zero once every worker has run once."
}
# HTH Guide Excerpt: end config-agent-env-hooks

# HTH Guide Excerpt: begin config-agent-env-audit
# Prove the control is real. Fails closed on the two combinations that look
# configured and enforce nothing: keyscan disabled with no pinned host keys, and
# BUILDKITE_CLEAN_CHECKOUT written into a file that never reads it.
audit_agent_env() {
  local rc=0 keyscan disconnect bootstrap hooks hook
  keyscan="$(read_cfg no-ssh-keyscan)"
  disconnect="$(read_cfg disconnect-after-job)"
  bootstrap="$(read_cfg bootstrap-script)"
  hooks="$(hooks_dir)"
  hook="${hooks}/environment"

  echo "config file          : ${AGENT_CFG}"
  echo "no-ssh-keyscan       : ${keyscan:-<unset> (agent default: false)}"
  echo "disconnect-after-job : ${disconnect:-<unset> (agent default: false)}"
  echo "bootstrap-script     : ${bootstrap:-<unset> (agent default: buildkite-agent bootstrap)}"
  echo "environment hook     : ${hook}"

  # 1. The silent-failure check. Nothing reads these out of the config file.
  if grep -qiE '^[[:space:]]*(BUILDKITE_)?CLEAN[-_]CHECKOUT[[:space:]]*=' "${AGENT_CFG}"; then
    echo "FAIL: a clean-checkout key is set in ${AGENT_CFG}. It is NOT an agent flag" >&2
    echo "      (absent from clicommand/agent_start.go) and is silently ignored." >&2
    echo "      Move it to the environment hook: $0 write-environment-hook" >&2
    rc=1
  fi

  # 2. Host-key trust.
  case "${keyscan}" in
    true)
      if [ -s "${KNOWN_HOSTS}" ]; then
        echo "PASS: automatic host-key acceptance is off and ${KNOWN_HOSTS} pins $(grep -c . "${KNOWN_HOSTS}") key(s)."
      else
        echo "FAIL: no-ssh-keyscan=true but ${KNOWN_HOSTS} is empty/missing." >&2
        echo "      StrictHostKeyChecking=yes with no pinned keys fails every checkout." >&2
        rc=1
      fi ;;
    *)
      echo "FAIL: no-ssh-keyscan is not true. The agent accepts whatever host key" >&2
      echo "      answers on first checkout (StrictHostKeyChecking=accept-new), or" >&2
      echo "      disables host-key checking outright on OpenSSH < 7.6." >&2
      rc=1 ;;
  esac

  # 3. The environment hook, and whether it actually says anything.
  if [ ! -f "${hook}" ]; then
    if [ "${disconnect}" = "true" ]; then
      echo "WARN: no environment hook, but disconnect-after-job=true — no second job"
      echo "      exists to contaminate. GIT_SSH_COMMAND is still overridable by a"
      echo "      pipeline env block; write the hook to close that."
    else
      echo "FAIL: no environment hook and the agent is persistent. Workspaces survive" >&2
      echo "      between jobs and BUILDKITE_CLEAN_CHECKOUT is set nowhere that reads it." >&2
      rc=1
    fi
  else
    # Own-block presence. Without it this pack's settings may still be in the
    # file by hand, but nothing can be rewritten safely and a re-run would
    # append a second copy of the policy rather than replace the first.
    if grep -q "HTH-BLOCK ${HTH_HOOK_BLOCK_ID}" "${hook}"; then
      echo "PASS: ${hook} carries the ${HTH_HOOK_BLOCK_ID} block."
    else
      echo "WARN: ${hook} exists but carries no '${HTH_HOOK_BLOCK_ID}' block, so"
      echo "      this pack does not own its contents. Run '$0 write-environment-hook'"
      echo "      to bring it under management (your current file is preserved and"
      echo "      backed up; the block is appended)."
    fi

    if grep -q 'BUILDKITE_CLEAN_CHECKOUT=true' "${hook}"; then
      echo "PASS: environment hook forces a clean checkout."
    elif [ "${disconnect}" = "true" ]; then
      echo "WARN: hook does not force a clean checkout; relying on disconnect-after-job."
    else
      echo "FAIL: environment hook does not export BUILDKITE_CLEAN_CHECKOUT=true, and" >&2
      echo "      this agent is persistent. One job's leftovers reach the next." >&2
      rc=1
    fi

    if grep -q 'StrictHostKeyChecking=yes' "${hook}" && grep -q '^unset GIT_SSH$' "${hook}"; then
      echo "PASS: environment hook rebuilds GIT_SSH_COMMAND and unsets GIT_SSH."
    else
      echo "FAIL: environment hook does not pin GIT_SSH_COMMAND. Because ssh resolves" >&2
      echo "      duplicate -o options first-wins and the agent APPENDS its own, a" >&2
      echo "      pipeline env block setting GIT_SSH_COMMAND or GIT_SSH defeats" >&2
      echo "      no-ssh-keyscan entirely." >&2
      rc=1
    fi

    # A hook anyone but root can rewrite is arbitrary code on every job.
    if [ -n "$(find "${hook}" -perm -g+w -o -perm -o+w 2>/dev/null)" ]; then
      echo "FAIL: ${hook} is group- or world-writable. Anyone who can edit it runs code" >&2
      echo "      on every job before the checkout, as the agent user." >&2
      rc=1
    fi
  fi

  # 4. Bootstrap wrapper integrity, when one is configured.
  if [ -n "${bootstrap}" ]; then
    local path="${bootstrap%% *}"
    if [ ! -x "${path}" ]; then
      echo "FAIL: bootstrap-script '${path}' is missing or not executable — no job can start." >&2
      rc=1
    elif [ -n "$(find "${path}" -perm -g+w -o -perm -o+w 2>/dev/null)" ]; then
      echo "FAIL: bootstrap-script '${path}' is group- or world-writable. It runs as the" >&2
      echo "      agent user on every job, before any of your other controls do." >&2
      rc=1
    else
      echo "PASS: bootstrap-script present and not group/world-writable."
    fi
  fi

  return "${rc}"
}
# HTH Guide Excerpt: end config-agent-env-audit

case "${1:-audit}" in
  propose-known-hosts)      shift; propose_known_hosts "$@" ;;
  accept-known-hosts)       shift; accept_known_hosts "$@" ;;
  apply-host-key-pinning)   apply_host_key_pinning ;;
  write-environment-hook)   write_environment_hook ;;
  write-bootstrap-wrapper)  write_bootstrap_wrapper ;;
  apply-ephemeral)          apply_ephemeral ;;
  audit)                    audit_agent_env ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-buildkite-3.09-agent-env.sh propose-known-hosts <host> [port]
                                            capture host keys + print fingerprints to verify
  hth-buildkite-3.09-agent-env.sh accept-known-hosts <staged-file>
                                            commit verified keys to known_hosts
  hth-buildkite-3.09-agent-env.sh apply-host-key-pinning
                                            set no-ssh-keyscan=true (refuses if known_hosts empty)
  hth-buildkite-3.09-agent-env.sh write-environment-hook
                                            clean checkout + GIT_SSH_COMMAND lock (the ONLY
                                            supported home for BUILDKITE_CLEAN_CHECKOUT)
  hth-buildkite-3.09-agent-env.sh write-bootstrap-wrapper
                                            thin bootstrap handler + bootstrap-script
  hth-buildkite-3.09-agent-env.sh apply-ephemeral
                                            disconnect-after-job=true
  hth-buildkite-3.09-agent-env.sh audit     prove enforcement is real (exit 1 on fail)

Order matters: propose/accept known hosts BEFORE apply-host-key-pinning.
Restart buildkite-agent after any apply-*; the config is read once at start.
Input controls (no-command-eval, allowed-plugins, redacted-vars, ...) live in
packs/buildkite/config/hth-buildkite-2.04-agent-untrusted-input.sh — run both.
USAGE
    exit 2 ;;
esac
